{ pkgs, ... }: {
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    media-session.enable = false;
    wireplumber.enable = true;
  };
  environment.systemPackages = with pkgs; [
    pavucontrol
    pulseaudio
    easyeffects
  ];
}
