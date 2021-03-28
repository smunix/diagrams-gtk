{
  description = "A very basic flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/master";
    smunix-diagrams-cairo.url = "github:smunix/diagrams-cairo/fix.diagrams";
    smunix-diagrams-lib.url = "github:smunix/diagrams-lib/fix.diagrams";
  }; 
  outputs =
    { self, nixpkgs, flake-utils, smunix-diagrams-lib,
      smunix-diagrams-cairo,
      ...
    }:
    with flake-utils.lib;
    with nixpkgs.lib;
    eachSystem [ "x86_64-linux" ] (system:
      let version = "${substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
          overlay = self: super:
            with self;
            with haskell.lib;
            with haskellPackages.extend(self: super: {
              inherit (smunix-diagrams-cairo.packages.${system}) diagrams-cairo;
              inherit (smunix-diagrams-lib.packages.${system}) diagrams-lib;
            });
            {
              diagrams-gtk = rec {
                package = overrideCabal (callCabal2nix "diagrams-gtk" ./. {}) (o: { version = "${o.version}-${version}"; });
              };
            };
          overlays = [ overlay ];
      in
        with (import nixpkgs { inherit system overlays; });
        rec {
          packages = flattenTree (recurseIntoAttrs { diagrams-gtk = diagrams-gtk.package; });
          defaultPackage = packages.diagrams-gtk;
        });
}
