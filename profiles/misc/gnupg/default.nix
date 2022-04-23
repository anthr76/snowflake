{ lib, ... }: {
  programs.gnupg.agent = {
    enable = true;
    #pinentryFlavor = "curses";
  };
}

