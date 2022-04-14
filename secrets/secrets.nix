{
  imports = [ <sops-nix/modules/sops> ];
  sops.defaultSopsFile = "./default.yaml";
  sops.age.generateKey = false;
  # sops.gnupg.home = "/home/anthonyjrabbito/.gnupg";
  sops.age.keyFile = "/home/anthonyjrabbito/.config/sops/age/keys.txt";
  sops.gnupg.sshKeyPaths = [];
  sops.secrets.anthonyjrabbito = {};
}
