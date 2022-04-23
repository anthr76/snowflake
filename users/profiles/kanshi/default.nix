{
  services.kanshi = {
    enable = true;
    profiles = {
      undocked = {
        outputs = [{
          criteria = "eDP-1";
          status = "enable";
          mode = "1920x1080";
          position = "0,0";
        }];
      };
      docked = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Unknown NX-EDG27  NIX27F17";
            mode = "2560x1440";
            position = "0,0";
          }
        ];
      };
    };
  };
}
