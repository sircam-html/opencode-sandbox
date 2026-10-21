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

          # Ensure lsof from nixpkgs is available in the script's PATH
          export PATH="${pkgs.lsof}/bin:$PATH"

          WORKSPACE="$HOME/.cache/opencode-sandbox"
          mkdir -p "$WORKSPACE"
          cd "$WORKSPACE"

          echo "🧬 Initializing containerized OpenCode application engines..."

          # Automatically clean up any stale processes using port 8642
          if lsof -i :8642 -t >/dev/null 2>&1; then
            echo "⚠️ Port 8642 is currently busy. Cleaning up stale ghost sessions..."
            kill -9 $(lsof -t -i:8642) 2>/dev/null || true
          fi

          echo "🚀 Launching OpenCode Server at http://127.0.0.1:8642 ..."
          echo "🌐 Open your browser and start chatting directly."

          # OPENCODE_SERVER_PASSWORD is intentionally omitted to prevent blocking local chat WebSockets
          exec ${pkgs.opencode}/bin/opencode web --hostname 127.0.0.1 --port 8642
        '';

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/opencode-web";
        };
      }
    );
}
