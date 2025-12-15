{pkgs, ...}: {
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
  environment.systemPackages = with pkgs; [pavucontrol pulseaudio];
  programs.noisetorch.enable = true;
  # Mumble for LAN use
  networking.firewall = {
    allowedTCPPorts = [64738];
    allowedUDPPorts = [64738];
  };
}
