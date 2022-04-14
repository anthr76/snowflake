{pkgs, lib, ...}: {
  programs.git = {
    enable = true;
    userName  = "Anthony Rabbito";
    userEmail = "hello@anthonyrabbito.com";
  };
}
