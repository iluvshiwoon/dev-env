{
  description = "A Nix-flake-based Lua development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";

  outputs = inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import inputs.nixpkgs { inherit system; };
        });
  in {
    devShells = forEachSupportedSystem ({ pkgs }: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          lua
          luarocks
          lua-language-server
          stylua              # Lua formatter
          selene              # Lua linter
          luacheck            # Another popular Lua linter
        ];

        # env = {
        #   # Set up LuaRocks to use local directory
        #   LUAROCKS_CONFIG = "${pkgs.luarocks}/etc/luarocks/config-5.1.lua";
        # };
        #
        # shellHook = ''
        #   # Create local LuaRocks directory if it doesn't exist
        #   mkdir -p .luarocks
        #
        #   # Set up local LuaRocks environment
        #   export LUAROCKS_PREFIX="$PWD/.luarocks"
        #   export LUA_PATH="$LUAROCKS_PREFIX/share/lua/5.1/?.lua;$LUAROCKS_PREFIX/share/lua/5.1/?/init.lua;$LUA_PATH"
        #   export LUA_CPATH="$LUAROCKS_PREFIX/lib/lua/5.1/?.so;$LUA_CPATH"
        #   export PATH="$LUAROCKS_PREFIX/bin:$PATH"
        #
        #   echo "Lua development environment loaded!"
        #   echo "- Lua version: $(lua -v)"
        #   echo "- LuaRocks available for package management"
        #   echo "- Local packages will be installed to .luarocks/"
        #   echo "- Language server (lua-language-server) available"
        #   echo "- Linting with luacheck and selene"
        #   echo "- Formatting with stylua"
        # '';
      };
    });
  };
}
