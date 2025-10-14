#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# Determine script directory - works for both development and installed versions
if [[ -f "/usr/local/share/devmagic/mklocalenv.sh" && "$0" == "/usr/local/bin/devmagic" ]]; then
    # Running as installed program
    script_dir="/usr/local/share/devmagic"
else
    # Running from development directory
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
fi

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-wiz] -p param_value arg1 [arg2...]
Make a local development environment for your website.

Basic options:
-h, --help              Print this help and exit
-v, --verbose           Print script debug info
-cwiz, --config-wizard  Start the configuration wizard
-wiz, --wizard          Start the wizard
-d, --domain            Local env domain name

Action Flags:
-c, --cert              Create SSL certificate for the domain
-cf, --config           Create Apache config file for the domain
-w, --web               Create local WordPress website for the domain
-ci, --cert-issuer      Create a local CA (Certificate Authority) for signing local SSL certificates

Install WP Options:
-dbn, --dbname          Name of the database
-dbp, --dbpass          DB Password. Default: Root123@
-dbu, --dbuser          DB User. Default: root
-dbpr, --dbprefix       Database tables prefix. Default: wp_
-dbf, --dbfile          Path to the .sql file to import
-t, --title             WP website title

Git Clone Options:
-pr, --projects         Clone multiple projects. Usage -pr git/clone/url/project.git{to}/local/path/to/the/folder{and}git/clone/url/project-2.git{to}/local/path/to/the/folder-2
-cr, --content-repo     Git repository URL for main project to clone into domain directory

Cleanup Options:
-rm, --remove           Remove/cleanup a local WordPress site
-rmwiz, --remove-wizard Start the cleanup wizard
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  devmagic_log_error "$msg"
  exit "$code"
}

find_base_dir() {
    # DESC:
    #         Locates the real directory of the script being run. Similar to GNU readlink -n
    # ARGS:
    #         None
    # OUTS:
    #         stdout: prints result
    # USAGE:
    #         baseDir="$(find_base_dir)"
    #         cp "$(find_base_dir "somefile.txt")" "other_file.txt"

    local _source
    local _dir

    # Is file sourced?
    if [[ ${_} != "${0}" ]]; then
        _source="${BASH_SOURCE[1]}"
    else
        _source="${BASH_SOURCE[0]}"
    fi

    while [ -h "${_source}" ]; do # Resolve $SOURCE until the file is no longer a symlink
        _dir="$(cd -P "$(dirname "${_source}")" && pwd)"
        _source="$(readlink "${_source}")"
        [[ ${_source} != /* ]] && _source="${_dir}/${_source}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    printf "%s\n" "$(cd -P "$(dirname "${_source}")" && pwd)"
}

source_utilities() {
  # DESC:
  #         Sources utility functions.  Absolute paths are required for shellcheck to correctly
  #         parse the sourced files
  # ARGS:
  #					$1 (Required):  Absolute path to the directory containing the utilities
  # OUTS:
  #					 0:  Success
  #					 1:  Failure
  # USAGE:
  #					source_utilities "$(find_base_dir)/../../shell-scripting-templates/utilities"

  local _utilsPath
  _utilsPath="${1}"

  if [ -f "${_utilsPath}/colors-logging.sh" ]; then
      source "${_utilsPath}/colors-logging.sh"
  else
      printf "%s\n" "ERROR: ${_utilsPath}/colors-logging.sh not found"
      exit 1
  fi

  if [ -f "${_utilsPath}/checks.sh" ]; then
      source "${_utilsPath}/checks.sh"
  else
      printf "%s\n" "ERROR: ${_utilsPath}/checks.sh not found"
      exit 1
  fi
}

source_includes() {
  # DESC:
  #         Sources utility functions.  Absolute paths are required for shellcheck to correctly
  #         parse the sourced files
  # ARGS:
  #					$1 (Required):  Absolute path to the directory containing the includes
  # OUTS:
  #					 0:  Success
  #					 1:  Failure
  # USAGE:
  #					source_includes "$(find_base_dir)/../../shell-scripting-templates/includes"

  local _utilsPath
  _utilsPath="${1}"

  if [ -f "${_utilsPath}/mkcert.sh" ]; then
    source "${_utilsPath}/mkcert.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/mkcert.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/mkcertissuer.sh" ]; then
    source "${_utilsPath}/mkcertissuer.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/mkcertissuer.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/mkconfig-ssl.sh" ]; then
    source "${_utilsPath}/mkconfig-ssl.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/mkconfig-ssl.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/mkwpwebsite.sh" ]; then
    source "${_utilsPath}/mkwpwebsite.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/mkwpwebsite.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/gitclone.sh" ]; then
      source "${_utilsPath}/gitclone.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/gitclone.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/rmwpwebsite.sh" ]; then
      source "${_utilsPath}/rmwpwebsite.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/rmwpwebsite.sh not found"
    exit 1
  fi
}

source_tools() {
  # DESC:
  #         Sources tools functions.  Absolute paths are required for shellcheck to correctly
  #         parse the sourced files
  # ARGS:
  #					$1 (Required):  Absolute path to the directory containing the tools
  # OUTS:
  #					 0:  Success
  #					 1:  Failure
  # USAGE:
  #					source_tools "$(find_base_dir)/../../shell-scripting-templates/tools"

  local _utilsPath
  _utilsPath="${1}"

  if [ -f "${_utilsPath}/wizard.sh" ]; then
    source "${_utilsPath}/wizard.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/wizard.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/devmagic-conf.sh" ]; then
    source "${_utilsPath}/devmagic-conf.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/devmagic-conf.sh not found"
    exit 1
  fi

  if [ -f "${_utilsPath}/rmwizard.sh" ]; then
    source "${_utilsPath}/rmwizard.sh"
  else
    printf "%s\n" "ERROR: ${_utilsPath}/rmwizard.sh not found"
    exit 1
  fi
}

############################################################
# Load the utilities                                       #
############################################################

# Source utility functions.
source_utilities "$(find_base_dir)/utilities"

############################################################
# Load the tools                                           #
############################################################

# Source tools functions.
source_tools "$(find_base_dir)/tools"

############################################################
# Load Dev Magic Config                                    #
############################################################

# Check if the array 'devmagic_config_defaults' is not declared and visible
if ! declare -p devmagic_config_defaults &>/dev/null; then
  echo "Error: devmagic_config_defaults array is not declared or visible."
  exit 1  # Exit with error status
fi

# Check if the array 'devmagic_config' is not declared and visible
if ! declare -p devmagic_config &>/dev/null; then
  echo "Error: devmagic_config array is not declared or visible."
  exit 1  # Exit with error status
fi

devmagic_conf_load

############################################################
# Load the dependencies                                    #
############################################################

# Source include functions.
source_includes "$(find_base_dir)/includes"

############################################################
# Command line parameter parsing                           #
############################################################

# Function to validate that a parameter value is provided
validate_param_value() {
  # DESC: Validates that a command line parameter has a non-empty value
  #       and that the value is not another parameter flag
  #
  # ARGS: $1 (string) - The parameter name/flag (e.g. -d, --domain)
  #       $2 (string) - The parameter value to validate
  #
  # OUTS: None
  #
  # USAGE:
  #       validate_param_value "-d" "${domain}"
  #       validate_param_value "--domain" "${domain}"
  #       (validate_param_value "-d" "${domain}") || die "Missing value for -d"
  #       (validate_param_value "--domain" "${domain}") || die "Missing value for --domain"
  #
  # DEPENDENCIES: None
  #
  # NOTE: If validation fails, script exits with error message

  local param_name="${1}"
  local param_value="${2}"
  
  if [[ -z "${param_value}" ]]; then
    die "Missing value for parameter: ${param_name}"
  fi

  # Check if the value starts with a dash, which likely means it's another parameter flag
  if [[ "${param_value:0:1}" == "-" ]]; then
    die "Invalid value for parameter ${param_name}: '${param_value}' appears to be another parameter flag"
  fi
}

# Parse command line parameters
parse_params() {
  # default values of variables set from params
  cert=0
  web=0
  config=0
  gitclone=0
  wizard=0
  has_action_flags=0
  config_wizard=0
  remove=0
  remove_wizard=0
  # domain is used for the certificate, config file and local environment website
  domain='' # local.example.com
  domain_prefix_arr=''
  domain_prefix='' # should has local if not add it
  # db data for the wp config file
  dbname='' #wordpressdb
  dbuser="${devmagic_config[WP_DB_USER]}" # root
  dbpass="${devmagic_config[WP_DB_PASSWORD]}" # Root123@
  dbprefix="${devmagic_config[WP_DB_PREFIX]}" # wp_
  dbfile=''
  # local enviroment website specific info
  title='Example Local Website'
  admin_user="${devmagic_config[WP_ADMIN_USER]}" # admin
  admin_password="${devmagic_config[WP_ADMIN_PASSWORD]}" # admin
  admin_email='' # admin@${domain}
  # Git repository options
  projects=''
  content_repo=''

  while :; do
    case "${1-}" in
    -h | --help)
      usage
      ;;
    -v | --verbose)
      set -x
      ;;
    --no-color)
      NO_COLOR=1
      ;;
    -ci | --cert-issuer)
      mkcertissuer
      has_action_flags=1
      ;;
    -c | --cert)
      cert=1 && has_action_flags=1
      ;;
    -w | --web)
      web=1 && has_action_flags=1
      ;;
    -cf | --config)
      config=1 && has_action_flags=1
      ;;
    -wiz | --wizard)
      wizard=1 && has_action_flags=1
      ;;
    -cwiz | --config-wizard)
      config_wizard=1 && has_action_flags=1
      ;;
    -rm | --remove)
      remove=1 && has_action_flags=1
      ;;
    -rmwiz | --remove-wizard)
      remove_wizard=1 && has_action_flags=1
      ;;
    -d | --domain)
      validate_param_value "$1" "${2-}"
      domain="${2-}"
      domain_prefix_arr=(${domain//./ })
      domain_prefix=${domain_prefix_arr[0]-}
      admin_email="admin@${2-}"
      shift
      ;;
    -dbn | --dbname)
      validate_param_value "$1" "${2-}"
      dbname="${2-}"
      shift
      ;;
    -dbu | --dbuser)
      validate_param_value "$1" "${2-}"
      dbuser="${2-}"
      shift
      ;;
    -dbp | --dbpass)
      validate_param_value "$1" "${2-}"
      dbpass="${2-}"
      shift
      ;;
    -dbpr | --dbprefix)
      validate_param_value "$1" "${2-}"
      dbprefix="${2-}"
      shift
      ;;
    -t | --title)
      validate_param_value "$1" "${2-}"
      title="${2-}"
      shift
      ;;
    -dbf | --dbfile)
      validate_param_value "$1" "${2-}"
      dbfile="${2-}"
      dbfile="${dbfile/#\~/$HOME}" # Expand ~ to $HOME if used
      dbfile="$(readlink -f "${2-}")" # Convert to absolute path
      shift
      ;;
    -pr | --projects)
      validate_param_value "$1" "${2-}"
      projects="${2-}"
      gitclone=1 && has_action_flags=1
      shift
      ;;
    -cr | --content-repo)
      validate_param_value "$1" "${2-}"
      content_repo="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # Show help if no action flags were provided
  if [[ $has_action_flags -eq 0 ]]; then
    usage
    exit 0
  fi

  # Check if domain is provided for actions that require it
  if [[ -z "$domain" && ( $cert -eq 1 || $config -eq 1 || $web -eq 1 || $remove -eq 1) ]]; then
    while [[ -z "$domain" ]]; do
        read -r -p "Domain is required for the selected actions. Please enter the domain name (e.g., local.example.com): " domain
    done
    # Extract the domain prefix and set the admin email
    domain_prefix_arr=(${domain//./ })
    domain_prefix=${domain_prefix_arr[0]-}
    admin_email="admin@${domain}"
  fi

  # check domain has prefix local if not add it
  if [[ "local" != "$domain_prefix" && ( $cert -eq 1 || $config -eq 1 || $web -eq 1 ) ]];
  then
    read -p "The domain name doesn't have the prefix 'local' Do you want to add it? (y/n): " -n 1 -r
    echo    # (optional) move to a new line
    case "$REPLY" in 
      y|Y ) domain=local.$domain && domain_prefix=local && admin_email="admin@$domain";;
    esac
  fi

  # Ensure dbname is set if web is requested
  if [[ $web -eq 1 ]]; then
    # Ensure dbname is provided
    if [[ -z "$dbname" ]]; then
      while [[ -z "$dbname" ]]; do
          read -r -p "Database name is required for setting up the WordPress site. Please enter the database name: " dbname
      done
    fi

    # Ensure admin_email is set
    if [[ -z "$admin_email" ]]; then
      admin_email="admin@${domain}"
    fi
  fi

  return 0
}

parse_params "$@"

############################################################
# Main program                                             #
############################################################

# Run the config wizard if requested
if [[ 1 == "$config_wizard" ]]
then
  devmagic_conf_wizard
fi

# Set variables with a wizard if requested.
if [[ 1 == "$wizard" ]]
then
  wizard
fi

# Run the cleanup wizard if requested
if [[ 1 == "$remove_wizard" ]]
then
  rmwizard
fi

# Create certificate if requested
if [[ 1 == "$cert" ]]
then
  devmagic_log_info "Creating certificate..."
  mkcert
fi

# Create Apache config file if requested
if [[ 1 == "$config" ]]
then
  devmagic_log_info "Making Apache configuration file..."
  mkconfig-ssl
fi

# Create local environment website if requested
if [[ 1 == "$web" ]]
then
  devmagic_log_info "Installing WordPress Locally..."
  mkwpwebsite
fi

# Clone additional Git repositories if requested
if [[ 1 == "$gitclone" ]]
then
  devmagic_log_info "Cloning additional Git repositories..."
  clone_projects
fi

# Remove/cleanup a local WordPress site if requested
if [[ 1 == "$remove" ]]
then
  devmagic_log_info "Cleaning up WordPress site..."
  cleanup_site "${domain}"
fi
