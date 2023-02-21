
alias fp := fix-permissions

@default:
  if ! which fzf > /dev/null 2>&1; then echo "fzf not installed. If on Ubuntu: Install the fzf package." && exit 1; fi
  @just --choose

fix-permissions:
  fd --type f --exclude .git --exec chmod 755

black:
  black .
