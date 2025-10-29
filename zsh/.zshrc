setopt interactivecomments
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt histignorealldups

[[ -d "$XDG_DATA_HOME"/zsh ]] || mkdir -p "$XDG_DATA_HOME"/zsh
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE="$XDG_DATA_HOME"/zsh/zsh_history
zstyle ':completion:*' cache-path "$XDG_DATA_HOME"/zsh/zcompcache
zstyle ':completion:*' menu select
zmodload zsh/complist
autoload -Uz compinit
compinit -d "$XDG_DATA_HOME"/zsh/zcompdump-$ZSH_VERSION
_comp_options+=(globdots)

bindkey -v
export KEYTIMEOUT=1

function zle-keymap-select zle-line-init {
  case $KEYMAP in
    vicmd) print -n '\e[2 q';;
    viins|main) print -n '\e[6 q';;
  esac
}
zle-line-finish() { echo -ne '\e[2 q' }
zle -N zle-line-init
zle -N zle-keymap-select
zle -N zle-line-finish

function vi-yank-pbcopy { zle vi-yank; echo "$CUTBUFFER" | pbcopy }
zle -N vi-yank-pbcopy
bindkey -M vicmd 'y' vi-yank-pbcopy

function vi-put-after-pbcopy { CUTBUFFER=$(pbpaste); zle vi-put-after }
zle -N vi-put-after-pbcopy
bindkey -M vicmd 'p' vi-put-after-pbcopy

function vi-put-before-pbcopy { CUTBUFFER=$(pbpaste); zle vi-put-before }
zle -N vi-put-before-pbcopy
bindkey -M vicmd 'P' vi-put-before-pbcopy

bindkey '^[[Z' reverse-menu-complete
bindkey -v '^?' backward-delete-char
bindkey -M vicmd -r :
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^K" kill-line
bindkey "^L" clear-screen
bindkey "^W" backward-kill-word
bindkey "^Y" yank
bindkey "^U" kill-whole-line
bindkey "^P" history-search-backward
bindkey "^N" history-search-forward

autoload edit-command-line; zle -N edit-command-line
bindkey '^[e' edit-command-line
bindkey -M vicmd '^[[P' vi-delete-char
bindkey -M vicmd '^[e' edit-command-line
bindkey -M visual '^[[P' vi-delete

alias ls="ls --color=auto"
alias ll="ls -AS"
alias c="printf '\e[H\e[3J'"
alias l="ls -AS"

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
  function e() {
    [ $# -ne 1 ] && return 1
    [ ! -d "$1" ] && mkdir -p "$1"
    cd "$1" || return 1
    direnv edit .
  }
fi

if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  bindkey -M vicmd '/' fzf-history-widget
  bindkey -M vicmd '?' fzf-history-widget
fi

if (( $+commands[nvim] )); then
  export MANPAGER="nvim +Man!"
  export {EDITOR,VISUAL}="nvim"
  alias vimdiff="nvim -d"
  alias {vi,vim}="nvim"
fi

if (( $+commands[orbctl] )); then
  eval "$(orbctl completion zsh)"
  compdef _orbctl orbctl
  compdef _orbctl orb
fi

if (( $+commands[tree] )); then
  alias t="tree -a -I '.git|.venv'"
fi

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

prompt="%m %B%~%b "
