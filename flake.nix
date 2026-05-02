{
  description = "Mi Página Personal en Servant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowBroken = true;  # ⬅️ PERMITE PAQUETES ROTOS
            problems.handlers = {
              servant-quickcheck.broken = "ignore";  # ⬅️ IGNORA ESTE PAQUETE
            };
          };
        };
        hsPkgs = pkgs.haskell.packages.ghc910;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.zlib
            pkgs.sqlite
            pkgs.gmp
            hsPkgs.stack
            hsPkgs.ghc
            hsPkgs.cabal-install
          ];
        };
      });
}
