
{
  description = "vendir";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    # packages
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # flake-parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # go
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # utils
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lib-extras = {
      url = "github:aldoborrero/lib-extras/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib.extend (l: _: (inputs.lib-extras.lib l));
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {inherit lib;};
    }
    {
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.treefmt-nix.flakeModule
      ];

      debug = false;

      systems = import inputs.systems;

      perSystem = {
        lib,
        pkgs,
        self',
        system,
        ...
      }: {
        # nixpkgs
        _module.args = {
          pkgs = lib.nix.mkNixpkgs {
            inherit system;
            inherit (inputs) nixpkgs;
            overlays = [
              inputs.gomod2nix.overlays.default
            ];
          };
        };

        # formatter
        treefmt.config = {
          projectRootFile = "flake.nix";
          flakeFormatter = true;
          flakeCheck = true;
          programs = {
            alejandra.enable = true;
            deadnix.enable = true;
            mdformat.enable = true;
            shfmt.enable = true;
            statix.enable = true;
            yamlfmt.enable = true;
          };
        };

        # packages
        packages = {
          vendir = pkgs.callPackage ./package.nix {};
        };

        # devshell
        devshells.default = {
          name = "vendir";
          packages =
            (with pkgs; [
              act
              awscli2
              delve
              gh
              go
              go-tools
              golangci-lint
              gomod2nix
              minio-client
              oras
              regctl
              regsync
              vhs
              yq-go
            ]);
          env = [
            {
              name = "NIX_PATH";
              value = "nixpkgs=${toString pkgs.path}";
            }
          ];
          commands = [
            # Utils
            {
              name = "fmt";
              category = "Utils";
              help = "Format the source tree";
              command = "nix fmt";
            }
            {
              name = "clean";
              category = "Utils";
              help = "Cleans any result produced by Nix or associated tools";
              command = "rm -rf result* *.qcow2";
            }

            # go
            {
              category = "dev";
              package = pkgs.gomod2nix;
            }
          ];
        };
      };
    };
}
