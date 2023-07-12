{pkgs, ... }:{
  home = {
    username = "anthony";
    homeDirectory = "/Users/anthony";
  };

  home.packages = with pkgs; [

  ];
}
