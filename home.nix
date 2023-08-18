{ config, pkgs, lib, ... }:
                
{       
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # EDIT: declare this in flake.nix to accomodate differnet users on differnt systems:
  # home.username = "user";
  # home.homeDirectory = "home";
                
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #     
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.
        
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # Doom Emacs dependencies:
    pkgs.ripgrep
    # pkgs.fd
    # pkgs.clang

    # Clojure dependencies:
    pkgs.clj-kondo

    (pkgs.writeShellScriptBin "e" ''
      emacs
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/vscode/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  
  home.sessionPath = [
    "$HOME/.config/emacs/bin"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      eval "$(direnv hook bash)"
    '';
  };

  programs.emacs.enable = true;

  programs.git = {
    enable = true;
    userName = "cloudspinner";
    userEmail = "stijn.tastenhoye@gmail.com";
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    prefix = "C-\\\\";
    terminal = "screen-256color";
    extraConfig = ''
      bind-key C-\\ last-window
    '';
  };

  home.activation = {
    installDoomEmacs = lib.hm.dag.entryAfter ["installPackages"] ''
      if [ ! -d "$HOME/.config/emacs" ]; then
        $DRY_RUN_CMD ${lib.getExe pkgs.git} clone --depth 1 https://github.com/doomemacs/doomemacs $HOME/.config/emacs
      fi
      if [ ! -d "$HOME/.config/doom" ]; then
        $DRY_RUN_CMD ${lib.getExe pkgs.git} clone https://github.com/cloudspinner/doom-emacs-config $HOME/.config/doom
      fi
    '';
  };
}
