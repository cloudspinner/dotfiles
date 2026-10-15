{ config, pkgs, lib, ... }:
                
let
  mosh = pkgs.mosh.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall + ''
      wrapProgram $out/bin/mosh-server \
        --set LOCALE_ARCHIVE "${pkgs.glibcLocales}/lib/locale/locale-archive" \
        --set-default MOSH_SERVER_NETWORK_TMOUT 2592000
    '';
  });
in
{
  imports = [ ./chat-mcp-refresh.nix ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Use nodejs_20 to avoid C++20 template-id constructor build issues
  nixpkgs.overlays = [
    (final: prev: {
      nodejs = prev.nodejs_20;
    })
  ];
  
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
    mosh

    pkgs.claude-code

    ## Emacs itself
    # pkgs.binutils       # native-comp needs 'as', provided by this
    pkgs.cmake  # native-comp needs cmake
    # 30.2 + native-comp. No epkgs needed: the terminal is now :term ghostel,
    # which Doom installs via straight (it ships its own native module).
    pkgs.emacs

    # Doom Emacs dependencies:
    pkgs.ripgrep
    pkgs.fd
    pkgs.clang

    # Clojure dependencies:
    pkgs.clojure
    pkgs.clojure-lsp
    pkgs.babashka

    (pkgs.writeShellScriptBin "e" ''
      SOCKET="/tmp/emacs$UID/server"
      env -u SSH_TTY COLORTERM=truecolor emacsclient --socket-name="$SOCKET" -t -a ""
    '')

    pkgs.cloudflared
    pkgs.oauth2-proxy
    pkgs.rclone

    pkgs.google-cloud-sdk

    # Plan 9 tools (for Acme):
    pkgs.plan9port
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
    XDG_CONFIG_HOME = "$HOME/.config";
    PLAN9 = "${pkgs.plan9port}/plan9";
  };
  
  home.sessionPath = [
    "$HOME/.config/emacs/bin"
    "$HOME/.local/bin"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  programs.bash = {
    enable = true;
    historySize = 50000;
    historyFileSize = 50000;
    historyControl = [ "erasedups" "ignorespace" ];
    shellOptions = [ "histappend" "checkwinsize" "cdspell" "globstar" "autocd" ];
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -lAh";
      grep = "grep --color=auto";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    initExtra = ''
      # Prevent Claude Code nested session false positives in Emacs terminals
      # (ghostel sets INSIDE_EMACS=ghostel, as vterm did before it).
      # See: https://github.com/anthropics/claude-agent-sdk-python/issues/573
      if [ -n "$INSIDE_EMACS" ]; then
        unset CLAUDECODE
      fi

      # Debian default prompt + git branch
      source ${pkgs.git}/share/git/contrib/completion/git-prompt.sh
      PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)")\$ '
    '';
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "cloudspinner";
      user.email = "stijn.tastenhoye@gmail.com";
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gist.github.com:".insteadOf = "https://gist.github.com/";
    };
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      hosts = [ "https://github.com" "https://gist.github.com" ];
    };
  };

  programs.tmux = {
    enable = true;
    # Keep the socket in /tmp. With secureSocket, home-manager exports
    # TMUX_TMPDIR=/run/user/$UID from hm-session-vars.sh, which only *login*
    # shells source -- so `ssh host tmux ...` and an interactive login end up
    # on different sockets and sessions appear to vanish.
    secureSocket = false;
    # Nord colours, matching Blink and Claude Code. Sourced directly rather than
    # via programs.tmux.plugins: the plugin's nord.tmux is bash (BASH_SOURCE,
    # [[ == ]]) but tmux run-shell uses /bin/sh, which is dash here, so it is a
    # silent no-op. Sourcing nord.conf also skips the plugin's status-bar
    # *content* (date/time segments), keeping our own "[#S]" status-left.
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    prefix = "C-\\\\";
    # tmux-256color (not screen-256color) so truecolor survives into Emacs.
    terminal = "tmux-256color";
    # Scrollback is the only scrollback on a phone/iPad: Blink's own buffer
    # stops at the tmux pane.
    historyLimit = 50000;
    mouse = true;
    extraConfig = ''
      bind-key C-\\ last-window

      # Pass 24-bit colour through to clients that handle it (Blink does).
      set -ga terminal-overrides ",*:RGB"

      source-file ${pkgs.tmuxPlugins.nord}/share/tmux-plugins/nord/src/nord.conf

      # The session name is effectively the tab label, and tmux's default
      # status-left-length of 10 truncates anything past "[kan-test]".
      set -g status-left-length 20

      # With tmux as the session switcher rather than one session per Blink
      # tab, killing the current session should move to another one, not throw
      # the client out of tmux altogether.
      set -g detach-on-destroy off

      # Close window 2 of 5 and the rest close the gap, so window numbers stay
      # in step with what the status bar shows (and with any Cmd+N bindings).
      set -g renumber-windows on

      # Let Claude Code's bell reach Blink, so a backgrounded tab can show it
      # is waiting on you rather than you polling each one.
      set -g visual-bell off
      set -g bell-action any

      # Claude Code specifics, the three settings everyone running it under
      # tmux ends up needing:
      #  - passthrough: tmux drops DCS-wrapped sequences by default, which kills
      #    OSC 52 copy-to-iOS-clipboard (Blink handles OSC 52 natively) and
      #    Claude Code's progress/notification sequences.
      #  - extended keys: without these, Shift+Enter submits the prompt instead
      #    of inserting a newline.
      set -g allow-passthrough on
      set -g set-clipboard external
      set -s extended-keys on
      set -as terminal-features "xterm*:extkeys"
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

      if [ ! -d "$HOME/.config/clojure" ]; then
        $DRY_RUN_CMD ${lib.getExe pkgs.git} clone https://github.com/cloudspinner/clojure-config $HOME/.config/clojure
      fi
    '';
  };
}
