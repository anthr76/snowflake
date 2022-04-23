let
  # set ssh public keys here for your system and user
  system =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwN29wh51MbW5kPWBTm91g+Ic0Q7yxDFls/7vReEXgz";
  user =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVERvbDIv7M0YlecZUKZQ3L2ylRPjqnIZayu48MDZDl";
  allKeys = [ system user ];
in { "secret.age".publicKeys = allKeys; }
