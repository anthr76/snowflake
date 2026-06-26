# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  pkgs,
  inputs ? (import ../nixpkgs.nix) {},
}: {
  # example = pkgs.callPackage ./example { };
  wayland-push-to-talk-fix = pkgs.callPackage ./wayland-push-to-talk-fix {};
  discover-overlay = pkgs.python3Packages.callPackage ./discover-overlay {};
  rpc-bridge = pkgs.callPackage ./rpc-bridge {};
  udpbroadcastrelay = pkgs.callPackage ./udpbroadcastrelay {};
  # TODO: Currently broken and unused.
  # led_matrix_monitoring = pkgs.callPackage ./led_matrix_monitoring { };
  kotlin-debug-adapter = pkgs.callPackage ./kotlin-debug-adapter {};
  scuttle = pkgs.callPackage ./scuttle {};
}
