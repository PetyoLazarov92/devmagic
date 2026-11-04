#!/usr/bin/env bash
#
# Functions for validating common use-cases

is_file() {
  # DESC:
  #					Validate that a given input points to a valid file
  # ARGS:
  #					$1 (required): Input to check
  # OUTS:
  #					0 - Input is a valid file
  #					1 - Input is not a valid file
  # USAGE:
  #					_varIsFile_ "${var}"
  # NOTES:
  #

  [[ $# == 0 ]] && printf "Missing required argument to %s\\n" "${FUNCNAME[0]}"

  [[ -f ${1} ]] && return 0 || return 1
}

is_dir() {
  # DESC:
  #					Validate that a given input points to a valid directory
  # ARGS:
  #					$1 (required): Input to check
  # OUTS:
  #					0 - Input is a directory
  #					1 - Input is not a directory
  # USAGE:
  #         _varIsDir_ "${var}"
  #         (is_dir "${var}") && printf "Is a directory" || printf "Not a directory"
  # NOTES:
  #

  [[ $# == 0 ]] && printf "Missing required argument to %s\\n" "${FUNCNAME[0]}"

  [[ -d ${1} ]] && return 0 || return 1
}

is_command_exists() {
  # DESC:
  #					Validate that a given command exists
  # ARGS:
  #					$1 (required): Command to check
  # OUTS:
  #					0 - The command exists
  #					1 - The command does not exist
  # USAGE:
  #         (is_command_exists "${var}") && printf "The command exists" || printf "The command does not exist"
  # NOTES:
  #

  [[ $# == 0 ]] && printf "Missing required argument to %s\\n" "${FUNCNAME[0]}"

  command -v "$1" >/dev/null 2>&1
}
