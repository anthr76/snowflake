{...}: {
  programs.nh = {
    enable = true;
    flake = "github:anthr76/snowflake";
    clean = {
      enable = true;
      extraArgs = "--keep 5";
    };
  };
}
