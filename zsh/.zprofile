typeset -U path PATH fpath FPATH

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

SHELL_SESSIONS_DISABLE=1
export CLICOLOR=1

export GOCACHE="$XDG_CACHE_HOME/go-build"
export GOPATH="$XDG_DATA_HOME/go"
export GOENV="$GOPATH/env"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"

path=(
  $HOME/.local/bin
  $CARGO_HOME/bin
  $GOPATH/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /Applications/OrbStack.app/Contents/MacOS/xbin
  $path
)
