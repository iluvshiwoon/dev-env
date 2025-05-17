{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs = inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import inputs.nixpkgs {inherit system;};
        });

    scriptDrvs = forEachSupportedSystem ({pkgs}: let
      getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
      forEachDir = exec: ''
        for dir in */; do
          (
            cd "''${dir}"

            ${exec}
          )
        done
      '';
    in {
      format = pkgs.writeShellApplication {
        name = "format";
        runtimeInputs = with pkgs; [nixpkgs-fmt];
        text = ''
          shopt -s globstar

          nixpkgs-fmt -- **/*.nix
        '';
      };

      # only run this locally, as Actions will run out of disk space
      build = pkgs.writeShellApplication {
        name = "build";
        text = ''
          ${getSystem}

          ${forEachDir ''
            echo "building ''${dir}"
            nix build ".#devShells.''${SYSTEM}.default"
          ''}
        '';
      };

      check = pkgs.writeShellApplication {
        name = "check";
        text = forEachDir ''
          echo "checking ''${dir}"
          nix flake check --all-systems --no-build
        '';
      };

      update = pkgs.writeShellApplication {
        name = "update";
        text = forEachDir ''
          echo "updating ''${dir}"
          nix flake update
        '';
      };
    });
  in
    {
      devShells = forEachSupportedSystem ({pkgs}: {
        default = pkgs.mkShell {
          packages = with scriptDrvs.${pkgs.system};
            [
              build
              check
              format
              update
            ]
            ++ [pkgs.nixpkgs-fmt];
        };
      });

      packages = forEachSupportedSystem (
        {pkgs}: rec {
          default = dvt;
          dvt = pkgs.writeShellApplication {
            name = "dvt";
            bashOptions = ["errexit" "pipefail"];
            text = ''
              if [ -z "''${1}" ]; then
                echo "no template specified"
                exit 1
              fi

              TEMPLATE=$1

              nix \
                --experimental-features 'nix-command flakes' \
                flake init \
                --template \
                "github:iluvshiwoon/dev-env#''${TEMPLATE}"
            '';
          };
        }
      );
    }
    // {
      templates = rec {
        c = {
          path = ./c;
          description = "C/C++ development environment";
        };

        # Aliases
        cpp = c;
      };
    };
}
