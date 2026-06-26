{pkgs, ...}: {
  services.easyeffects = {
    enable = true;
    preset = "Perfect-EQ";
  };
  xdg.configFile = {
    preset = {
      target = "easyeffects/output/Perfect-EQ.json";
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/refs/heads/master/Perfect%20EQ.json";
        name = "Perfect-EQ";
        sha256 = "sha256:0cppf5kcpp2spz7y38n0xwj83i4jkgvcbp06p1l005p2vs7xs59f";
      };
    };
  };
}
