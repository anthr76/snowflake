# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs, inputs ? (import ../nixpkgs.nix) { } }: {
  # example = pkgs.callPackage ./example { };
  wayland-push-to-talk-fix = pkgs.callPackage ./wayland-push-to-talk-fix { };
  vulkan-hdr-layer = pkgs.callPackage ./vulkan-hdr-layer { };
  discover-overlay = pkgs.python3Packages.callPackage ./discover-overlay { };
  # FIXME: Make this a overlay
  coredns-snowflake = pkgs.callPackage ./coredns-snowflake { };
  lightworks_2023_02 = pkgs.callPackage ./lightworks_2023_02 { };
}
