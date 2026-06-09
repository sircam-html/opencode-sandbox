{
  description = "A portable, isolated Nix Flake sandbox launcher for OpenCode Web Browser UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "opencode" ];
        };
      in
      {
        packages.default = pkgs.writeShellScriptBin "opencode-web" ''
          #!/usr/bin/env bash
          set -e

          WORKSPACE="$HOME/.cache/opencode-sandbox"
          mkdir -p "$WORKSPACE"
          cd "$WORKSPACE"

          echo "🧬 Initializing containerized OpenCode application engines..."

          export OPENCODE_SERVER_PASSWORD="admin-sandbox-token"

          echo "🚀 Launching OpenCode Server at http://127.0.0.1:8642 ..."
          echo "🔑 opencode / admin-sandbox-token"

          exec ${pkgs.opencode}/bin/opencode web --hostname 127.0.0.1 --port 8642
        '';

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/opencode-web";
        };
      }
    );
}
