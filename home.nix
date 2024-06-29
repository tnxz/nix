{
  pkgs,
  lib,
  ...
}: {
  disabledModules = ["targets/darwin/linkapps.nix"];

  home = {
    stateVersion = "24.11";

    packages = with pkgs; [
      (nerdfonts.override {fonts = ["Iosevka"];})
      tree
    ];

    sessionVariables = {
      CLICOLOR = 1;
      SHELL_SESSIONS_DISABLE = 1;
    };

    shellAliases = {
      l = "ls -At";
      ll = "ls -Alth";
      c = "echo -ne '\\033c\\033[3J'";
      t = "tree -a";
    };
  };

  fonts.fontconfig.enable = true;

  targets.darwin.defaults = {
    NSGlobalDomain = {
      AppleShowAllFiles = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
    finder._FXShowPosixPathInTitle = true;
  };

  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      dotDir = ".config/zsh";
    };
    zoxide.enable = true;
    fzf.enable = true;
    git.enable = true;
    ripgrep.enable = true;
    fd.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withPython3 = false;
      withRuby = false;
    };
  };
}
