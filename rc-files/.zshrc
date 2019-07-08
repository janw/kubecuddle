
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

source /usr/share/zgen/zgen.zsh

if ! zgen saved; then
    zgen oh-my-zsh
    zgen oh-my-zsh plugins/git
    zgen oh-my-zsh plugins/kubectl
    zgen oh-my-zsh plugins/helm
    zgen oh-my-zsh plugins/sudo
    zgen load zsh-users/zsh-completions src
    zgen load denysdovhan/spaceship-prompt spaceship
    zgen save
fi

set show-all-if-ambiguous on
set completion-ignore-case on

export HISTSIZE=1000
export SAVEHIST=1000

# Theme of choice: https://github.com/denysdovhan/spaceship-prompt
SPACESHIP_PROMPT_ORDER=(
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  kubecontext   # Kubectl context section
  char          # Prompt character
)
SPACESHIP_DIR_TRUNC_PREFIX="…/"
SPACESHIP_PROMPT_DEFAULT_PREFIX=""
SPACESHIP_CHAR_SYMBOL="❯ "
SPACESHIP_KUBECONTEXT_COLOR=magenta
SPACESHIP_CHAR_COLOR_SUCCESS=magenta
SPACESHIP_CHAR_COLOR_FAILURE=red
SPACESHIP_DIR_COLOR=silver
