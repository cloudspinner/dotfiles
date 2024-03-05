{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    homeConfigurations = {
      vscode-x86_64-linux = let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
        };
        hm = import home-manager {
          inherit pkgs;
          inherit system;
        };
      in hm.lib.homeManagerConfiguration {
	inherit pkgs;
        system = system;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
          {
            home = {
              username = "vscode";
              homeDirectory = "/home/vscode";
            };
            # GITHUB_TOKEN is used by Codespace for authentication,
            # but also by gh auth login.
            # Avoid clash (see https://github.com/cli/cli/issues/3799):
            programs.bash.shellAliases = {
              gh = "env -u GITHUB_TOKEN gh";
            };
            # Use default Codespace credential helper (see /etc/gitconfig):
            programs.gh.gitCredentialHelper.enable = false;
          }
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix

      };
      
      stijn-aarch64-linux = let
        system = "aarch64-linux";
        pkgs = import nixpkgs {
          inherit system;
        };
        hm = import home-manager {
          inherit pkgs;
          inherit system;
        };
      in hm.lib.homeManagerConfiguration {
        inherit pkgs;
        system = system;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix
          {
            home = {
              username = "stijn";
              homeDirectory = "/home/stijn";
            };
          }
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix

      };
    };
}
