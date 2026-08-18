{
  inputs,
  pkgs,
  ...
}: {
  catppuccin.helix.enable = true;
  programs.helix = {
    enable = true;
    # nvf/nvim owns $EDITOR -- see ../nvim. Helix stays installed as a
    # secondary editor.
    defaultEditor = false;
    settings = {
      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = ["collapse_selection" "keep_primary_selection"];
      };
    };
  };
}
