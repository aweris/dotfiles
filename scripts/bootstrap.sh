#!/usr/bin/env bash

set -e

# Directory of this script
readonly SCRIPTS_DIR=$(dirname "$0")

# Fully resolved path to the root of the dotfiles repo
readonly DOTFILES_ROOT="$(builtin cd "${SCRIPTS_DIR}/.."; pwd -P)"

# Prints a info message
info() {
  echo -e "\r  [ \033[00;34m..\033[0m ] $1\n"
}

# Prints a user interaction message
user() {
  echo -e "\r  [ \033[0;33m??\033[0m ] $1\n"
}

# Prints a success message
success() {
  echo -e "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

# Prints a error message and exits the script
error() {
  echo -e "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# Setups local git config if not already set, and sets private information which should not be committed to the repository
setup_gitconfig() {
  if [ -f git/gitconfig.local.symlink ]; then
    info 'skipping gitconfig.local.symlink setup, file already exists. Please remove it if you want to re-run this step or modify it manually'
    return
  fi

  info 'setup gitconfig'

  git_credential='cache'

  user ' - What is your github author name?'
  # shellcheck disable=SC2162
  read -e git_authorname

  user ' - What is your github author email?'
  # shellcheck disable=SC2162
  read -e git_authoremail

  sed -e "s/AUTHORNAME/$git_authorname/g" \
    -e "s/AUTHOREMAIL/$git_authoremail/g" \
    -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" \
    git/gitconfig.local.symlink.example >git/gitconfig.local.symlink

  success 'git/gitconfig.local is created'
}

# Symlinks the src file($1) to the destination($2)
link_file() {
  local src=$1 dst=$2

  local overwrite backup skip action

  if [ -f "${dst}" ] || [ -d "${dst}" ] || [ -L "${dst}" ]; then

    if [ "${overwrite_all}" == "false" ] && [ "${backup_all}" == "false" ] && [ "${skip_all}" == "false" ]; then

      local currentSrc

      currentSrc="$(readlink "${dst}")"

      if [ "${currentSrc}" == "${src}" ]; then

        skip=true

      else

        # Ask user for action if the destination already exists
        user "File already exists: ${dst} ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        # shellcheck disable=SC2162
        read -n 1 action

        case "$action" in
        o)
          overwrite=true
          ;;
        O)
          overwrite_all=true
          ;;
        b)
          backup=true
          ;;
        B)
          backup_all=true
          ;;
        s)
          skip=true
          ;;
        S)
          skip_all=true
          ;;
        *) ;;

        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]; then
      rm -rf "${dst}"
      success "removed ${dst}"
    fi

    if [ "$backup" == "true" ]; then
      mv "${dst}" "${dst}.backup"
      success "moved ${dst} to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]; then
      success "skipped $src"
    fi
  fi

  # "false" or empty
  if [ "$skip" != "true" ]; then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

# Symlinks all files in DOTFILES_ROOT/<topic-name>/*.symlink to $HOME directory[[
install_dotfiles() {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  symlink_files=$(find -H "${DOTFILES_ROOT}" -maxdepth 2 -name '*.symlink' -not -path '*.git*')

  # Recursively find all files in the DOTFILES_ROOT directory that end with .symlink
  for src in ${symlink_files}; do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done
}

# Symlinks all files in DOTFILES_ROOT/<topic-name>/*.symlink.xdg.config to $HOME/.config/ directory
install_xdg_configs() {
  info 'installing xdg configs'

  local overwrite_all=false backup_all=false skip_all=false

  symlink_files=$(find -H "${DOTFILES_ROOT}" -maxdepth 2 -name '*.symlink.xdg.config' -not -path '*.git*')

  # Recursively find all files in the DOTFILES_ROOT directory that end with .symlink
  for src in ${symlink_files}; do
    dst="$HOME/.config/$(basename "${src%.*.*.*}")"
    link_file "$src" "$dst"
  done
}

# Main run function
run_cmd() {
  setup_gitconfig
  install_dotfiles
  install_xdg_configs
  echo '  All installed!'
}

# Execute the run_cmd function
run_cmd "$@"
