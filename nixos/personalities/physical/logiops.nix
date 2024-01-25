{pkgs, config, ...}:
{
  environment.systemPackages = with pkgs; [ logiops ];
  systemd.services.logiops = {
    description = "An unofficial userspace driver for HID++ Logitech devices";
    enable = true;
    restartTriggers = [ config.environment.etc."logid.cfg".source ];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.logiops}/bin/logid";
    };
  };
  environment.etc."logid.cfg".text =
    ''
      devices: (
        {
            name: "MX Master 3S";
            smartshift:
            {
                on: true;
                threshold: 30;
                torque: 50;
            };
            hiresscroll:
            {
                hires: false;
                invert: false;
                target: false;
                up: {
                    mode: "Axis";
                    axis: "REL_WHEEL";
                    axis_multiplier: 1.0;
                },
                down: {
                    mode: "Axis";
                    axis: "REL_WHEEL";
                    axis_multiplier: -1.0;
                },
            };
            dpi: 1500;

            buttons: (
                {
                    cid: 0xc3;
                    action =
                    {
                        type: "Gestures";
                        gestures: (
                            {
                                direction: "Up";
                                mode: "OnRelease";
                                action =
                                {
                                    type: "Keypress";
                                    keys: ["KEY_LEFTMETA"];
                                };
                            },
                            {
                                direction: "Down";
                                mode: "OnRelease";
                                action =
                                {
                                    type: "Keypress";
                                    keys: ["KEY_LEFTMETA", "KEY_LEFTSHIFT", "KEY_DOWN"];
                                };
                            },
                            {
                                direction: "Left";
                                mode: "OnRelease";
                                action =
                                {
                                    type: "Keypress";
                                    keys: ["KEY_LEFTMETA", "KEY_LEFTSHIFT", "KEY_LEFT"];
                                };
                            },
                            {
                                direction: "Right";
                                mode: "OnRelease";
                                action =
                                {
                                    type: "Keypress";
                                    keys = ["KEY_LEFTMETA", "KEY_LEFTSHIFT", "KEY_RIGHT"];
                                }
                            },
                            {
                                direction: "None"
                                mode: "OnRelease";
                                action =
                                {
                                    type: "Keypress";
                                    keys: ["KEY_LEFTMETA", "KEY_ENTER"];
                                }
                            }
                        );

                    };
                },
                {
                    cid: 0x52;
                    action =
                    {
                        type: "Keypress";
                        keys: ["KEY_RIGHTCTRL", "KEY_PRINT"]
                    };
                },
                {
                    cid: 0xc4;
                    action =
                    {
                        type: "ToggleSmartshift";
                    };
                }
            );
        },
        {
            name: "PRO X 2";
            dpi: 32000;
        }
      );
    '';
}
