{
  description = "A Nix-flake-based C/C++ development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";

  outputs = inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import inputs.nixpkgs { inherit system; };
        });
  in {
    devShells = forEachSupportedSystem ({ pkgs }: let
      stdenv = pkgs.clangStdenv;
    in {
      default =
        pkgs.mkShell.override
        {
          inherit stdenv;
        }
        {
          packages = with pkgs;
            [
              clang-tools
              man-pages           # For standard C libc man pages
              man-pages-posix     # POSIX man pages
            ]
            ++ (
              if system == "aarch64-darwin"
              then []
              else [gdb valgrind]
            );

          env = {
            CLANGD_FLAGS = "--query-driver=${pkgs.lib.getExe stdenv.cc}";
          };

          shellHook = ''
            # Ensure MANPATH includes local documentation
            export MANPATH="${pkgs.man-pages}/share/man:${pkgs.man-pages-posix}/share/man:${pkgs.valgrind}/share/man:$MANPATH"
          '';
        };
    });
  };
}

