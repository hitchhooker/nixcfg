# CHAOSzsh
# f.g. user@hostname /etc/

# terminal
export TERMINAL=alacritty
export EDITOR=nvim
source /etc/set-environment

# PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# vim mode with indicators
bindkey -v
export KEYTIMEOUT=1

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# cursor shape for different modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'  # block cursor
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'  # beam cursor
  fi
}
zle -N zle-keymap-select

# start with beam cursor
echo -ne '\e[5 q'
precmd() { echo -ne '\e[5 q' }

# prompt with mode indicator
setopt PROMPT_SUBST
git_prompt() { [[ -d .git ]] && echo "± " || echo "$ " }
vim_mode() {
  echo "${${KEYMAP/vicmd/[N]}/(main|viins)/[I]}"
}
PROMPT='%F{yellow}$(vim_mode)%f %F{green}%B%n@%m%b%f %F{cyan}%~%f $(git_prompt)'

# update prompt on mode change
function zle-line-init zle-keymap-select {
  zle reset-prompt
}
zle -N zle-line-init

# vim keys in tab complete menu
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# useful vim bindings
bindkey -v '^?' backward-delete-char  # backspace works in insert
bindkey '^W' backward-kill-word        # ctrl-w in insert mode
bindkey '^R' history-incremental-search-backward  # keep ctrl-r search
bindkey '^P' up-history               # ctrl-p/n for history
bindkey '^N' down-history
bindkey '^A' beginning-of-line        # ctrl-a/e still work in insert
bindkey '^E' end-of-line

# CTRL+Z
bindkey '^Z' vi-cmd-mode # enter normal mode

# ctrl + arrow keys
bindkey '^[[1;5C' forward-word        # ctrl+right
bindkey '^[[1;5D' backward-word       # ctrl+left
# bindkey '^[[1;5A' history-search-backward  # ctrl+up
# bindkey '^[[1;5B' history-search-forward   # ctrl+down
bindkey '^[[A' history-beginning-search-backward # ctrl+up
bindkey '^[[B' history-beginning-search-forward # ctrl+down

# plain arrows for substring search
# bindkey '^[[A' up-line-or-search      # up arrow
# bindkey '^[[B' down-line-or-search    # down arrow
bindkey '^[[A' up-line-or-beginning-search    # up arrow
bindkey '^[[B' down-line-or-beginning-search  # down arrow

# history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000 # limit for perf
SAVEHIST=1000 # --||--
setopt HIST_IGNORE_ALL_DUPS

# completion
autoload -Uz compinit && compinit -C

# options
setopt NO_BEEP
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt EXTENDED_GLOB
setopt NULL_GLOB

# aliases
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'
alias -- -='cd -'

# git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gst='git status -sb'
alias gp='git push'
alias gl='git pull'
alias gca='git commit --amend'
alias gco='git checkout'
alias gaa='git add -A'
alias gcm='git commit -m'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias rotko='cd ~/rotko'
alias nixos='cd /etc/nixos'

# common commands
alias v='vi'
alias c='cat'
alias h='history'
alias cl='clear'
alias ns='nix-shell -p'
alias nsr='sudo nixos-rebuild switch'
alias nsru='sudo nixos-rebuild switch --upgrade'
alias dr='docker'
alias dc='docker compose'
alias dps='docker ps'
alias k='kubectl'

# ssh shortcuts
alias sbkk='ssh -i ~/.ssh/unlabored/ansible_mikrotik'

# file operations
alias rmrf='rm -rf'
alias mkdp='mkdir -p'
# safety nets #TODO: just create .bak files with 24h deletion timer
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

# process management
alias psg='pgrep -af'
alias kl='sudo killall'

# python/web
alias py='python3'
alias pys='python3 -m http.server'
alias bi='bun install'
alias br='bun run'
alias bd='bun run dev'
alias bb='bun run build'

# systemctl
alias sc='systemctl'
alias scs='systemctl status'
alias scr='systemctl restart'

# quick edits
alias zshrc='vi ~/.zshrc'
alias vimrc='vi ~/.vimrc'
alias nixconf='sudo nvim /etc/nixos/configuration.nix'

# rsync
alias rs='rsync -avh --progress'
alias rsd='rsync -avh --progress --delete'
alias rsn='rsync -avhn --progress'  # dry run
alias rsu='rsync -avhu --progress'  # update only
alias rsx='rsync -avhX --progress'  # preserve extended attrs
alias rsz='rsync -avhz --progress'  # compress

alias kbref='sudo modprobe -r i2c_hid_acpi && sudo modprobe i2c_hid_acpi'

# print execution time for slow commands
REPORTTIME=2

# SSH agent
[[ -z "$SSH_AUTH_SOCK" && -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]] && \
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

export PATH=/home/alice/.opencode/bin:$PATH
alias celestia='/usr/local/bin/celestia'

# bun
export PATH="$HOME/.bun/bin:$PATH"

# claude-dev aliases
alias cc='distrobox enter claude -- claude'
alias ccc='distrobox enter claude -- claude --continue'
alias cci='distrobox enter claude -- sudo pacman -Suy'
alias ccy='distrobox enter claude -- yay'
alias ccb='distrobox enter claude -- claude --dangerously-skip-permissions'
alias distro='distrobox enter claude --'
for conf in ~/.zshrc.d/*.zsh; do source "$conf"; done

# fix claude aliases with full path
alias cc='distrobox enter claude -- /home/alice/.cache/.bun/bin/claude'
alias ccc='distrobox enter claude -- /home/alice/.cache/.bun/bin/claude --continue'
alias ccb='distrobox enter claude -- /home/alice/.cache/.bun/bin/claude --dangerously-skip-permissions'
