{ pkgs, config, ... }: {
  accounts.email.accounts.gmail = {
    thunderbird.enable = true;
    realName = "Anthony Rabbito";
    address = "ted437@gmail.com";
    userName = "ted437@gmail.com";
    flavor = "gmail.com";
  };
  accounts.email.accounts.personal = {
    thunderbird.enable = true;
    primary = true;
    realName = "Anthony Rabbito";
    address = "hello@anthonyrabbito.com";
    userName = "hello@anthonyrabbito.com";
    imap = {
      host = "imap.migadu.com";
      port = 993;
    };
    smtp = {
      host = "smtp.migadu.com";
      port = 465;
    };
  };
  programs.thunderbird = {
    enable = true;
    profiles."default" = {
      isDefault = true;
      settings = {
        "datareporting.healthreport.uploadEnabled" = false;
        "font.name.sans-serif.x-western" = config.fontProfiles.regular.family;
        "mail.incorporate.return_receipt" = 1;
        "mail.markAsReadOnSpam" = true;
        "mail.spam.logging.enabled" = true;
        "mail.spam.manualMark" = true;
        "offline.download.download_messages" = 1;
        "offline.send.unsent_messages" = 1;
      };
    };
  };
}
