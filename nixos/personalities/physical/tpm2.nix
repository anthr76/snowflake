{
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
    applyUdevRules = true;
  };
  environment.sessionVariables.TSS2_LOG = "fapi+NONE";
}
