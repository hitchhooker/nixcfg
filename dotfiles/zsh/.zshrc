DISABLE_AUTO_TITLE="true"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="chaos"
plugins=(git)
source $ZSH/oh-my-zsh.sh

if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
. "$HOME/.cargo/env"
