system "defaults write -g ApplePressAndHoldEnabled -bool false"
system "defaults write -g InitialKeyRepeat -int 10"
system "defaults write -g KeyRepeat -int 1"
system "defaults write com.apple.dock persistent-apps -array"
tap "disrupted/neovim-nightly"
tap "oven-sh/bun"
tap "yihui/tinytex"
brew "alejandra"
brew "fd"
brew "ffmpeg"
brew "fzf"
brew "gh"
brew "go", postinstall: "/opt/homebrew/bin/go telemetry off"
brew "gofumpt"
brew "goimports"
brew "openjdk", postinstall: <<~BASH
  mkdir -p ~/Library/Java/JavaVirtualMachines
  ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk ~/Library/Java/JavaVirtualMachines/openjdk.jdk"
BASH
brew "google-java-format"
brew "gopls"
brew "python@3.14"
brew "jdtls"
brew "lazydocker"
brew "lazygit"
brew "lua-language-server"
brew "node"
brew "pyright"
brew "python@3.13"
brew "ripgrep"
brew "ruff"
brew "rust"
brew "rust-analyzer"
brew "stow"
brew "stylua"
brew "tree"
brew "tree-sitter-cli"
brew "ty"
brew "typescript-language-server"
brew "uv", postinstall: <<~BASH
  /opt/homebrew/bin/uv tool install --python 3.13 --with="setuptools,audioop-lts" manimgl
  /opt/homebrew/bin/uv tool install --python 3.13 manim
  /opt/homebrew/bin/uv tool install yt-dlp
BASH
brew "zig"
brew "zls"
brew "zoxide"
brew "oven-sh/bun/bun"
brew "yihui/tinytex/tinytex", args: ["HEAD"], postinstall: <<~BASH
  /opt/homebrew/bin/tlmgr install amsmath babel-english cbfonts-fd cm-super count1to ctex doublestroke \
  dvisvgm everysel fontspec frcursive fundus-calligra gnu-freefont jknapltx latex-bin \
  mathastext microtype multitoc physics preview prelim2e ragged2e relsize rsfs setspace \
  standalone tipa wasy wasysym xcolor xetex xkeyval
  /opt/homebrew/bin/brew postinstall tinytex
  /opt/homebrew/bin/brew unlink tinytex
  /opt/homebrew/bin/brew link tinytex
BASH
cask "font-iosevka-nerd-font", greedy: true
cask "font-iosevka-ss03", greedy: true
cask "helium-browser", greedy: true
cask "kitty", greedy: true
cask "neovim-nightly", greedy: true
cask "orbstack", greedy: true
cask "raycast", greedy: true
