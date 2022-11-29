{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, flake-utils, nixpkgs, ... }:
    let
      isRelease = false;
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};
        zipfs-rw = (pkgs.callPackage ./. {
          fuse = if pkgs.stdenv.isDarwin then pkgs.osxfuse else pkgs.fuse3;
          self = zipfs-rw;
        }).overrideAttrs (oldAttrs: lib.optionalAttrs (!isRelease) {
          pname = oldAttrs.pname + "-unstable";
          version = self.lastModifiedDate;
        });
      in
      {
        packages = {
          default = zipfs-rw;
          inherit zipfs-rw;
        };
        devShells.default = pkgs.callPackage ./shell.nix { inherit zipfs-rw; };
        devShells.fuse2 = pkgs.callPackage ./shell.nix { zipfs-rw = zipfs-rw.override { inherit (pkgs) fuse; }; };
        devShells.fuse3 = pkgs.callPackage ./shell.nix { zipfs-rw = zipfs-rw.override { fuse = pkgs.fuse3; }; };
        devShells.osxfuse = pkgs.callPackage ./shell.nix { zipfs-rw = zipfs-rw.override { fuse = pkgs.osxfuse; }; };
        checks = zipfs-rw.passthru.tests;
      }
    );
}
