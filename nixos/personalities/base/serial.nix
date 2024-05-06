{ config, lib, pkgs, ... }:
let
  # Based on https://unix.stackexchange.com/questions/16578/resizable-serial-console-window
  resize = pkgs.writeShellScriptBin "resize" ''
    export PATH=${pkgs.coreutils}/bin
    if [ ! -t 0 ]; then
      # not a interactive...
      exit 0
    fi
    TTY="$(tty)"
    if [[ "$TTY" != /dev/ttyS* ]] && [[ "$TTY" != /dev/ttyAMA* ]] && [[ "$TTY" != /dev/ttySIF* ]]; then
      # probably not a known serial console, we could make this check more
      # precise by using `setserial` but this would require some additional
      # dependency
      exit 0
    fi
    old=$(stty -g)
    stty raw -echo min 0 time 5

    printf '\0337\033[r\033[999;999H\033[6n\0338' > /dev/tty
    IFS='[;R' read -r _ rows cols _ < /dev/tty

    stty "$old"
    stty cols "$cols" rows "$rows"
  '';
in
{
    boot.kernelParams = [ "console=ttyS0,115200" ];

    # set terminal size once after login
    environment.loginShellInit = "${resize}/bin/resize";

    # allows user to change terminal size when it changed locally
    environment.systemPackages = [ resize ];

    # default is something like vt220... however we want to get alt least some colors...
    systemd.services."serial-getty@".environment.TERM = "xterm-256color";

    # also make grub respond on serial consoles
    boot.loader.grub.extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input --append serial
      terminal_output --append serial
    '';
}
