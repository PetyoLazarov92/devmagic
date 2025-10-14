#!/usr/bin/env bash

wizard_welcome() {
  devmagic_section_header "Welcome to the Dev Magic Wizard 🪄"
  echo
  cat <<EOF
$(echo -e ${PURPLE})We will ask you a few questions to can create
a magical environment for your local development.
$(echo -e ${NOFORMAT})
EOF
}

wizard_msg() {
  echo >&2 ${2-} -e "${1-}"
}

wizard() {
  # Colors loaded from utilities

  # Local flags
  local WITH_SSL=''
  local WITH_CF=''
  local WITH_WEB=''
  local WITH_DB_IMPORT=''
  local WITH_NEW_USER=''
  local WITH_GIT=''
  local WITH_PROJECT_REPO=''

  wizard_welcome

  while true; do
    # Set the domain name.
    if [[ -z ${domain} ]]; then
      read -p "$(wizard_msg "${BLUE}Enter ${CYAN}domain${BLUE} (local.example.com): ${NOFORMAT}" -n)" domain_input
      if [[ -z ${domain_input} ]]; then
        wizard_msg "${RED}Domain name can't be empty!${NOFORMAT}"
        continue # Go to the top of the loop
      fi

      domain=${domain_input} 
      domain_prefix_arr=(${domain//./ })
      domain_prefix=${domain_prefix_arr[0]}
      admin_email="admin@$domain"

      if [[ "local" != "$domain_prefix" ]]
      then
        while true; do
          read -p "$(wizard_msg "${ORANGE}The domain name ${CYAN}$domain${ORANGE} doesn't have the prefix 'local' Do you want to add it? (y/n): ${NOFORMAT}" -n)" local_input
          case "$local_input" in
            [yY][eE][sS] | [yY] ) domain=local.$domain && domain_prefix=local && admin_email="admin@$domain"; break;;
            [nN][oO] | [nN] ) break;;
            * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
          esac
        done
      fi
    fi

    echo ${domain}

    # Set the cert flag.
    if [[ -z ${WITH_SSL} ]]; then
      while true; do
        read -p "$(wizard_msg "${BLUE}Would you like to create an SSL Certificate? (y/n): ${NOFORMAT}" -n)" ssl_input
        case "$ssl_input" in
          [yY][eE][sS] | [yY] ) WITH_SSL=1; break;;
          [nN][oO] | [nN] ) WITH_SSL=0; break;;
          * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
        esac
      done

      cert=${WITH_SSL}
    fi

    echo ${cert}

    # Set the config flag.
    if [[ -z ${WITH_CF} ]]; then
      while true; do
        read -p "$(wizard_msg "${BLUE}Would you like to create an Apache config file? (y/n): ${NOFORMAT}" -n)" cf_input
        case "$cf_input" in
          [yY][eE][sS] | [yY] ) WITH_CF=1; break;;
          [nN][oO] | [nN] ) WITH_CF=0; break;;
          * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
        esac
      done

      config=${WITH_CF}
    fi

    echo ${config}

    # Ask about cloning a project repository
    if [[ -z ${WITH_PROJECT_REPO} ]]; then
      while true; do
        read -p "$(wizard_msg "${BLUE}Would you like to clone a project repository into the domain folder? (y/n): ${NOFORMAT}" -n)" project_repo_input
        case "$project_repo_input" in
          [yY][eE][sS] | [yY] ) WITH_PROJECT_REPO=1; break;;
          [nN][oO] | [nN] ) WITH_PROJECT_REPO=0; break;;
          * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
        esac
      done
      
      if [[ 1 == ${WITH_PROJECT_REPO} ]]; then
        read -e -p "$(wizard_msg "${ORANGE}Enter the Git repository URL for the project: ${NOFORMAT}" -n)" content_repo_url
        if [[ ! -z ${content_repo_url} ]]; then
          content_repo="${content_repo_url}"
        else
          wizard_msg "${YELLOW}No repository URL provided, will use standard WordPress installation.${NOFORMAT}"
          WITH_PROJECT_REPO=0
        fi
      fi
    fi
    
    # Set Git cloning options for additional repositories
    if [[ -z ${WITH_GIT} ]]; then
      while true; do
        read -p "$(wizard_msg "${BLUE}Would you like to clone additional Git repositories? (y/n): ${NOFORMAT}" -n)" git_input
        case "$git_input" in
          [yY][eE][sS] | [yY] ) WITH_GIT=1; break;;
          [nN][oO] | [nN] ) WITH_GIT=0; break;;
          * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
        esac
      done

      gitclone=${WITH_GIT}
      
      if [[ 1 == ${gitclone} ]]; then
        # Ask for Git repo URLs
        while true; do
          read -e -p "$(wizard_msg "${ORANGE}Enter additional Git repository URLs in format: ${CYAN}git_url{to}local_path{and}another_git_url{to}another_path${ORANGE}: ${NOFORMAT}" -n)" projects_input
          if [[ -z ${projects_input} ]]; then
            while true; do
              read -p "$(wizard_msg "${ORANGE}No repositories entered. Continue without additional Git cloning? (y/n): ${NOFORMAT}" -n)" skip_git
              case "$skip_git" in
                [yY][eE][sS] | [yY] ) gitclone=0; break 2;;
                [nN][oO] | [nN] ) break;;
                * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
              esac
            done
          else
            projects="${projects_input}"
            break
          fi
        done
      fi
    fi
    
    # Set the web flag.
    if [[ -z ${WITH_WEB} ]]; then
      # If project repo is selected, we automatically need web setup
      if [[ 1 == ${WITH_PROJECT_REPO} ]]; then
        WITH_WEB=1
        web=1
        wizard_msg "${BLUE}WordPress setup will be performed with the cloned project repository.${NOFORMAT}"
      else
        while true; do
          read -p "$(wizard_msg "${BLUE}Would you like to create a WordPress website? (y/n): ${NOFORMAT}" -n)" web_input
          case "$web_input" in
            [yY][eE][sS] | [yY] ) WITH_WEB=1; break;;
            [nN][oO] | [nN] ) WITH_WEB=0; break;;
            * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
          esac
        done
        web=${WITH_WEB}
      fi

      if [[ 1 == ${web} ]]; then
        # Set db info
        local website_db_vars=( "dbname" "dbuser" "dbpass" "dbprefix" "dbfile" )
        for var_name in "${website_db_vars[@]}"; do
          declare -n var_ref=${var_name}
          echo "${var_name} -> ${var_ref}"

          while true; do
            if [[ 'dbfile' == ${var_name} ]]; then
              if [[ -z ${WITH_DB_IMPORT} ]]; then
                while true; do
                  read -p "$(wizard_msg "${BLUE}Would you like to import DB from a .sql file? (y/n): ${NOFORMAT}" -n)" dbf_input
                  case "$dbf_input" in
                    [yY][eE][sS] | [yY] ) WITH_DB_IMPORT=1; break;;
                    [nN][oO] | [nN] ) WITH_DB_IMPORT=0; break;;
                    * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
                  esac
                done

                # With DB import
                if [[ 1 == ${WITH_DB_IMPORT} ]]; then
                  while true; do
                    # Set dbfile var.
                    read -e -p "$(wizard_msg "${ORANGE}Enter ${CYAN}${var_name}${ORANGE} (path to the .sql file): ${NOFORMAT}" -n)" var_value_input
                    if [[ -z ${var_value_input} ]]; then
                      wizard_msg "${RED}The value for the ${CYAN}${var_name}${RED} can't be empty!${NOFORMAT}"
                      continue # Go to the top of the loop
                    fi

                    # Expand tilde to home directory
                    var_value_input="${var_value_input/#\~/$HOME}"
                    # Symbolic link check
                    if [[ -L ${var_value_input} ]]; then
                      var_value_input="$(readlink -f ${var_value_input})"
                    fi
                    echo "Resolved path: ${var_value_input}"
                    # Check if file exists and is it .sql
                    if [[ ! -f ${var_value_input} || ${var_value_input: -4} != ".sql" ]]; then
                      wizard_msg "${RED}The file ${CYAN}${var_value_input}${RED} does not exist or is not a .sql file! Please provide a valid file path.${NOFORMAT}"
                      continue # Go to the top of the loop
                    fi

                    # Set a value for dbfile path
                    var_ref="${var_value_input}"
                    break
                  done
                fi
              fi
            else
              if [[ -z ${var_ref} ]]; then
                read -p "$(wizard_msg "${ORANGE}Enter ${CYAN}${var_name}${ORANGE}: ${NOFORMAT}" -n)" var_value_input
                if [[ -z ${var_value_input} ]]; then
                  wizard_msg "${RED}The value for the ${CYAN}${var_name}${RED} can't be empty!${NOFORMAT}"
                  continue # Go to the top of the loop
                fi

                # Set a value
                var_ref="${var_value_input}"
              else
                read -p "$(wizard_msg "${ORANGE}Enter ${CYAN}${var_name}${ORANGE} or leave empty for the default value (${BOLD}${var_ref}${NORMAL}${ORANGE}): ${NOFORMAT}" -n)" var_value_default_input
                if [[ ! -z ${var_value_default_input} ]]; then
                  # Set a new value if not empty.
                  var_ref="${var_value_default_input}"
                fi
              fi
            fi

            break
          done

          echo "${var_name} -> ${!var_name}"
        done

        # Set user info
        local website_user_vars=( "admin_user" "admin_password" "admin_email" )
        for var_name in "${website_user_vars[@]}"; do
          declare -n var_ref=${var_name}
          echo "${var_name} -> ${var_ref}"

          # With DB import
          if [[ 1 == ${WITH_DB_IMPORT} && -z ${WITH_NEW_USER} ]]; then
            # Ask for new user after import
            while true; do
              read -p "$(wizard_msg "${BLUE}Would you like to add a new user after DB import? (y/n): ${NOFORMAT}" -n)" with_user_input
              case "$with_user_input" in
                [yY][eE][sS] | [yY] ) WITH_NEW_USER=1; break;;
                [nN][oO] | [nN] ) WITH_NEW_USER=0; break;;
                * ) wizard_msg "${RED}We need your answer to continue.${NOFORMAT}";;
              esac
            done
          elif [[ -z ${WITH_NEW_USER} ]]; then
            # If we do not have an DB Import we need to add new user
            WITH_NEW_USER=1
          fi

          # Add user. TODO: add check for empty values in the mkwpwevsite.sh
          if [[ 1 == ${WITH_NEW_USER} ]]; then
            read -p "$(wizard_msg "${ORANGE}Enter ${CYAN}${var_name}${ORANGE} or leave empty for the default value (${BOLD}${var_ref}${NORMAL}${ORANGE}): ${NOFORMAT}" -n)" var_value_default_input
            if [[ ! -z ${var_value_default_input} ]]; then
              # Set a new value if not empty.
              var_ref="${var_value_default_input}"
            fi
          fi

          echo "${var_name} -> ${!var_name}"
        done

        # Set Title if there is no DB import
        if [[ 0 == ${WITH_DB_IMPORT} ]]; then
          read -p "$(wizard_msg "${ORANGE}Enter ${CYAN}title${ORANGE} or leave empty for the default value (${BOLD}${title}${NORMAL}${ORANGE}): ${NOFORMAT}" -n)" title_default_input
          if [[ ! -z ${title_default_input} ]]; then
            # Set a new value if not empty.
            title="${title_default_input}"
          fi
        fi

        echo ${title}
      fi
    fi

    echo ${web}

    break # Valid input given so exit the loop.
  done
}
