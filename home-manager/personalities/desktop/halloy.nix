{config, ...}: {
  sops.secrets.irc-password = {};

  catppuccin.halloy.enable = true;
  programs.halloy = {
    enable = true;
    settings = {
      buffer.channel.topic = {
        enabled = true;
      };
      servers = {
        liberachat = {
          channels = [
            "#halloy"
          ];
          nickname = "anthr76";
          server = "irc.libera.chat";
        };
        btn = {
          nickname = "anthr76";
          server = "irc.broadcasthe.net";
          port = 6697;
          nick_password_file = config.sops.secrets.irc-password.path;
        };
        fl = {
          nickname = "phonebook0531";
          server = "irc.filelist.io";
          channels = [
            "#filelist"
            "#english"
          ];
          nick_password_file = config.sops.secrets.irc-password.path;
        };
        ipt = {
          nickname = "Sixtyfo";
          server = "irc.iptorrents.com";
          channels = [
            "#iptorrents"
          ];
          nick_password_file = config.sops.secrets.irc-password.path;
        };
        # TODO: Currently broken
        hdtorrents = {
          nickname = "anthr76";
          server = "irc.p2p-network.net";
          port = 6697;
          channels = [
            "#HD-Torrents"
            "#HD-Torrents.Announce"
          ];
        };
      };
    };
  };
}
