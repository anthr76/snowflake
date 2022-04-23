{ pkgs, lib, ... }: {
  programs.git = {
    enable = true;
    userName = "Anthony Rabbito";
    delta.enable = true;
    signing.signByDefault = true;
  };
}
