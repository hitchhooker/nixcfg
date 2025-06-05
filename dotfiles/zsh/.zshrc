# CHAOSzsh

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# SSH agent
[[ -z "$SSH_AUTH_SOCK" && -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]] && \
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Prompt
setopt PROMPT_SUBST
git_prompt() { [[ -d .git ]] && echo "±" || echo "🕸" }
PROMPT='%F{green}%B%n@%m%b%f %F{cyan}%~%f $(git_prompt) %# '

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_ALL_DUPS

# Completion
autoload -Uz compinit && compinit -C

# Options
setopt NO_BEEP
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# Key bindings - Emacs mode
bindkey -e
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[H' beginning-of-line    # Home
bindkey '^[[F' end-of-line          # End
bindkey '^[[3~' delete-char         # Delete
bindkey '^[[A' up-line-or-search    # Up arrow
bindkey '^[[B' down-line-or-search  # Down arrow

# Aliases
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gst='git status -sb'
alias gp='git push'
alias gl='git pull'

# Show execution time for slow commands
REPORTTIME=2
