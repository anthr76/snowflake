(self: super: {
  # use PR commit here to use new version of pinentry
  yubikey-agent = super.buildGoModule {
    inherit (super.yubikey-agent.drvAttrs)
      pname doCheck nativeBuildInputs buildInputs buildPhase installPhase
      postPatch subPackages postInstall;
    inherit (super.yubikey-agent) meta;
    version = "0.1.5+main";
    src = super.fetchFromGitHub {
      owner = "FiloSottile";
      repo = "yubikey-agent";
      rev = "6d9db9c29100daacbe83e74653c79c94acc5958d";
      sha256 = "mrdZcKD61S94ZkVH93SJhozmsXW/22ho08WMCrDEwhs=";
    };
    vendorSha256 = "dqUV0+exeLbL20geWX1gqoir+nGDuYKDASC6DcJJwI8=";
  };
})
