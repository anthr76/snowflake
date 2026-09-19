{pkgs, ...}: {
  # SSH forwards TERM but not the terminfo database, so a Ghostty client lands
  # on a host that has never heard of xterm-ghostty and anything using a pager
  # fails with "unknown terminal type". This is the terminfo output only, not
  # the terminal -- nixpkgs' own ghostty package recommends exactly this for
  # remote machines.
  environment.systemPackages = [pkgs.ghostty.terminfo];
}
