{pkgs, config,...}:
{
  imports = [
    ./vscode
    ./fonts.nix
    ./ghostty.nix
    ./chat
    ./agentic-coding.nix
  ];

  home.packages = with pkgs; [
    raycast
    maccy
    betterdisplay
    secretive
  ];
  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;
  #programs.ssh.matchBlocks."*".extraOptions."IdentityAgent" = "${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  home.sessionVariables = {
    SSH_AUTH_SOCK="${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  };


}
