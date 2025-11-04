typeset -U path PATH fpath FPATH

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

if [[ $(uname) == "Darwin" ]]; then

  if [ -d "$XDG_DATA_HOME/TinyTeX/bin/universal-darwin" ]; then
    path+=("$XDG_DATA_HOME/TinyTeX/bin/universal-darwin")
  else
    echo "Installing TinyTeX"
    [ -d "$XDG_DATA_HOME" ] || mkdir -p $XDG_DATA_HOME
    curl -# -fSL https://yihui.org/tinytex/TinyTeX-1.tgz | tar xz -C $XDG_DATA_HOME
    path+=("$XDG_DATA_HOME/TinyTeX/bin/universal-darwin")
  fi

  SHELL_SESSIONS_DISABLE=1
  export CLICOLOR=1

  path=(
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /opt/homebrew/opt/llvm/bin
    $path
    /Applications/OrbStack.app/Contents/MacOS/xbin
  )

  fpath+=(
    /Applications/OrbStack.app/Contents/Resources/completions/zsh
    /opt/homebrew/share/zsh/site-functions
  )

  export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
fi

if [[ -d /opt/orbstack-guest ]]; then
  export GH_TOKEN=$(mac security find-generic-password -s "gh:github.com" -w | while IFS=: read -A parts; do base64 -d <<< "${parts[2]}"; done)
fi

export GOPATH="$XDG_DATA_HOME/go"
export GOCACHE="$XDG_CACHE_HOME/go-build"
export GOENV="$GOPATH/env"
path=("$GOPATH/bin" $path)

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
path=("$CARGO_HOME/bin" $path)
