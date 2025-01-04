{ pkgs, ... }: {
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    pkcs11.package = pkgs.tpm2-pkcs11.override {
      fapiSupport = false;
    };
    tctiEnvironment.enable = true;
    applyUdevRules = true;
  };
  environment.sessionVariables.TSS2_LOG = "fapi+NONE";
}
