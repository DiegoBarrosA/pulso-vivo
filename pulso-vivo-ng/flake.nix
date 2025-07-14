{
  description = "Angular development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {system = system;};
    in {
      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.yarn
          pkgs.nodejs
          pkgs.nodePackages."@angular/cli"
        ];

        shellHook = ''
          echo "Setting up Angular development environment..."
            npm install
        '';
      };
    });
}
