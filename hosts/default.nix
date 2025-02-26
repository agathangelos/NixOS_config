#
#  These are the different profiles that can be used when building NixOS.
#
#  flake.nix 
#   └─ ./hosts  
#       ├─ default.nix *
#       ├─ configuration.nix
#       ├─ home.nix
#       └─ ./laptop
#            ├─ ./default.nix
#            └─ ./home.nix 
#

{ lib, inputs, nixpkgs, home-manager, user, location, nixos-hardware, astro-nvim, ... }:

let
  system = "x86_64-linux"; # System architecture

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true; # Allow proprietary software
  };

  lib = nixpkgs.lib;
in
{
  laptop = lib.nixosSystem {
    # Laptop profile
    inherit system;
    specialArgs = {
      inherit inputs user location;
      host = {
        hostName = "laptop";
        mainMonitor = "eDP-1";
      };
    };
    modules = [
      # petclinic.nixosModules.default
      # ({ pkgs, ... }: {
      #   services.petclinic = {
      #     enable = true;
      #   };
      # })

      ./configuration.nix
      ./laptop
      nixos-hardware.nixosModules.dell-precision-3541
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user;
          inherit astro-nvim;
          inherit inputs;
          host = {
            hostName = "laptop";
            mainMonitor = "eDP-1";
            secondMonitor = "DP-1"; #DP1            | DisplayPort-1
          };
        };
        home-manager.users.${user} = {
          imports = [ (import ./home.nix) (import ./laptop/home.nix) ];
        };
      }
    ];
  };
  vm = lib.nixosSystem {
    # Laptop profile
    inherit system;
    specialArgs = {
      inherit inputs user location;
      host = {
        hostName = "nixos-vm";
      };
    };
    modules = [
      ./configuration.nix
      ./vm
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user;
          inherit astro-nvim;
          inherit inputs;
          host = {
            hostName = "vm";
          };
        };
        home-manager.users.${user} = {
          imports = [ (import ./home.nix) (import ./vm/home.nix) ];
        };
      }
    ];
  };
}
