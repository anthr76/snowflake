{ pkgs, ... }: {
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    pkcs11.package = pkgs.tpm2-pkcs11-esapi;
    tctiEnvironment.enable = true;
    applyUdevRules = true;
  };
}
