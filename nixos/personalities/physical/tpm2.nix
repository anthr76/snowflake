{
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
    applyUdevRules = true;
  };
  environment.variables.TSS2_LOG = "fapi+NONE";
}
