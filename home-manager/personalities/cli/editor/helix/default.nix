{inputs, pkgs, ...}:
{
  catppuccin.helix.enable = true;
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = [ "collapse_selection" "keep_primary_selection" ];
      };
    };
  };
}
