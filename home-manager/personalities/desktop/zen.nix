{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];
  programs.zen-browser = {
    enable = true;
    profiles."default" = {
      containersForce = true;
      containers = {
        Personal = {
          color = "purple";
          icon = "fingerprint";
          id = 1;
        };
        Work = {
          color = "blue";
          icon = "briefcase";
          id = 2;
        };
        Shopping = {
          color = "yellow";
          icon = "cart";
          id = 3;
        };
      };
      spacesForce = true;
      spaces = let
        containers = config.programs.zen-browser.profiles."default".containers;
      in {
        "Space" = {
          id = "c6de089c-410d-4206-961d-ab11f988d40a";
          position = 1000;
        };
        "Work" = {
          id = "cdd10fab-4fc5-494b-9041-325e5759195b";
          icon = "briefcase";
          container = containers."Work".id;
          position = 2000;
        };
        "Shopping" = {
          id = "78aabdad-8aae-4fe0-8ff0-2a0c6c4ccc24";
          icon = "cart";
          container = containers."Shopping".id;
          position = 3000;
        };
      };
    };
  };
}
