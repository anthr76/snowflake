{
  pkgs,
  inputs,
  ...
}: let
  reshade = inputs.nix-reshade.packages.${pkgs.system}.reshade;
  reshade-shaders = inputs.nix-reshade.packages.${pkgs.system}.reshade-shaders;
  d3dcompiler = inputs.nix-reshade.packages.${pkgs.system}.d3dcompiler_47-dll;
in {
  imports = [
    ../users/anthony
    ../users/anthony/linux.nix
    ../personalities/desktop
    ../personalities/desktop/mangohud.nix
    # ../personalities/desktop/wayland-wm/hyprland
  ];

  home.packages = [
    reshade
    reshade-shaders
    d3dcompiler
  ];

  # Stable paths for ReShade
  # Symlink these to your game directory:
  #   ln -sf ~/.local/share/reshade/ReShade32.dll /path/to/game/d3d9.dll
  #   ln -sf ~/.local/share/reshade/d3dcompiler_47.dll /path/to/game/
  #   ln -sf ~/.local/share/reshade-shaders /path/to/game/reshade-shaders
  home.file.".local/share/reshade/ReShade32.dll".source = "${reshade}/lib/reshade/ReShade32.dll";
  home.file.".local/share/reshade/ReShade64.dll".source = "${reshade}/lib/reshade/ReShade64.dll";
  home.file.".local/share/reshade/d3dcompiler_47.dll".source = "${d3dcompiler}/lib/d3dcompiler_47.dll";
  home.file.".local/share/reshade-shaders".source = "${reshade-shaders}/reshade-shaders";
}
