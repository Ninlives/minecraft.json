{
  description = "Database for minecraft launcher.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    with nixpkgs.lib;
    with builtins;
    let
      importJSONFiles = dir:
        listToAttrs (map (fp: {
          name = removeSuffix ".json" (baseNameOf fp);
          value = importJSON fp;
        }) (filesystem.listFilesRecursive dir));
    in eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        py = pkgs.python3.withPackages (p: [ p.requests ]);
      in {
        apps.update = mkApp {
          drv = let
            snippet = dir: ''
              pushd ./${dir}
              ${py}/bin/python update.py
              popd
            '';
          in pkgs.writeShellScriptBin "update" ''
            set -e
            ${snippet "vanilla"}
            ${snippet "fabric"}
          '';
        };
      }) // {
        manifests = importJSON ./vanilla/manifests.json;
        versions = importJSONFiles ./vanilla/versions;
        assets = importJSONFiles ./vanilla/asset_indices;
        fabric.profiles = importJSON ./fabric/profiles.json;
        fabric.libraries = importJSON ./fabric/libraries.json;
        fabric.loaders = importJSON ./fabric/loaders.json;
      };
}
