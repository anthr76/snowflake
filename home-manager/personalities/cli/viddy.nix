{ pkgs, ... }: {
  home.packages = with pkgs; [ viddy ];
  programs.fish.functions = {
    vdy = { body = "viddy -d -n 1 --shell fish $argv[1..-1]"; };
  };
}
