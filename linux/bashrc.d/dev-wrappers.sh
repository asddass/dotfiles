# ------------------------------------------------------------------------------
# Custom Dev Wrappers (sourced from ~/.bashrc via bashrc.d loop)
# ------------------------------------------------------------------------------

# Auto-jump to Linux home if opened in Windows drive (prevents slow I/O)
case "$PWD" in /mnt/c/Users/*) cd ~ ;; esac

alias fd=fdfind

# Block npm & yarn in favor of pnpm
npm() {
  if [[ " install i add " =~ " $1 " ]]; then
    echo -e "\033[0;31m[BLOCKED]\033[0m Use 'pnpm $*' instead." && return 1
  fi
  command npm "$@"
}

yarn() {
  if [[ " install i add " =~ " $1 " ]] || [ -z "$1" ]; then
    echo -e "\033[0;31m[BLOCKED]\033[0m Use 'pnpm $*' instead." && return 1
  fi
  command yarn "$@"
}

# Block pip in favor of uv
pip() {
  if [[ " install " =~ " $1 " ]]; then
    echo -e "\033[0;31m[BLOCKED]\033[0m Use 'uv pip $*' or 'uv add' instead." && return 1
  fi
  command pip "$@"
}