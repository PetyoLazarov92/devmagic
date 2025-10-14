#!/usr/bin/env bash
#
# Dev Magic - Git Clone Helpers

#######################################
# Function: clone_projects
# Description: Clones multiple git repositories to specified local paths.
# 
# This function parses a string containing multiple git repository URLs 
# and their corresponding local paths, then clones each repository.
# The input string uses {and} as a delimiter between repository pairs
# and {to} as a delimiter between a repository URL and its local path.
#
# Global Variables:
#   projects - String containing repository URLs and local paths
#              Format: "url1{to}path1{and}url2{to}path2{and}..."
#
# Arguments:
#   None (uses global $projects variable)
#
# Returns:
#   None
#######################################
clone_projects() {
  projects_arr=("${projects//\{and\}/ }")

  for i in "${projects_arr[@]}"
  do
    git_projects_arr=("${i//\{to\}/ }")

    git_url=${git_projects_arr[0]}
    local_path=${git_projects_arr[1]}

    clone_single_project "${git_url}" "${local_path}"
  done
}

#######################################
# Function: clone_single_project
#
# Description:
#   Clones a single Git repository to a specified local path.
#   The folder name is derived from the Git URL.
#
# Arguments:
#   $1 - git_url    - The URL of the Git repository to clone
#   $2 - local_path - The local path where the repository will be cloned
#
# Returns:
#   0 - Success
#   1 - Error if git_url or local_path is empty
#   Returns the exit status of the git clone command otherwise
#
# Example usage:
#   clone_single_project "https://github.com/user/repo.git" "/home/user/projects"
#######################################
clone_single_project() {
  local git_url=$1
  local local_path=$2

  if [[ -z "${git_url}" || -z "${local_path}" ]]; then
    devmagic_log_error "Git URL or local path is empty. Cannot clone repository."
    return 1
  fi

  folder_name_arr=("${git_url//\// }")
  folder_name=("${folder_name_arr[-1]//./ }") # Takes the first element

  # Add exclusion for folder_name shellcheck SC2128 (Expanding an array without an index only gives the first element).
  # shellcheck disable=SC2128
  devmagic_msg "${BLUE}Cloning ${RED}${git_url} ${BLUE}-> ${GREEN}${local_path%/}/${folder_name}${BLUE}...${NOFORMAT}"

  # Add exclusion for folder_name shellcheck SC2128 (Expanding an array without an index only gives the first element).
  # shellcheck disable=SC2128
  git clone "${git_url}" "${local_path%/}/${folder_name}" || true # %/ - removes a trailing slash

  return $?
}

#######################################
# Clone a Git repository to a specified domain directory
# 
# This function clones a Git repository from a provided URL to a specified
# domain directory. It performs validation checks to ensure both parameters
# are provided and that the destination directory is either empty or doesn't
# exist. After cloning, it adds the directory to Git's safe.directory
# configuration to avoid dubious ownership issues.
#
# Arguments:
#   $1 - git_url    The URL of the Git repository to clone
#   $2 - domain_dir The target directory where the repository will be cloned
#
# Returns:
#   0 on success, 1 on failure (when parameters are missing or directory exists and is not empty)
#
# Example usage:
#   clone_to_domain "https://github.com/user/repo.git" "/var/www/domain.com"
#######################################
clone_to_domain() {
  local git_url=$1
  local domain_dir=$2

  if [[ -z "${git_url}" || -z "${domain_dir}" ]]; then
    devmagic_log_error "Git URL or domain directory is empty. Cannot clone repository."
    return 1
  fi

  # Check if directory exists and is not empty
  if [[ -d "${domain_dir}" ]] && [[ "$(ls -A "${domain_dir}")" ]]; then
    devmagic_log_error "Domain directory ${domain_dir} already exists and is not empty. Cannot clone repository."
    return 1
  fi

  devmagic_msg "${BLUE}Cloning ${RED}${git_url} ${BLUE}-> ${GREEN}${domain_dir}${BLUE}...${NOFORMAT}"

  # Use git clone with specific target directory
  git clone "${git_url}" "${domain_dir}" || true

  # If you encounter dubious ownership issues, add an exception for this directory
  git config --global --add safe.directory "${domain_dir}"

  return $?
}
