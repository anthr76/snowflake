channels: final: prev: {

  __dontExport = true; # overrides clutter up actual creations

  inherit (channels.latest)
    gnupg
    pcsclite
    yubikey-manager
    ccid
    cachix
    dhall
    discord
    rage
    nixpkgs-fmt
    qutebrowser
    signal-desktop
    starship
    deploy-rs
    sway-launcher-desktop
    google-chrome-dev
    super-productivity
    #element-desktop
    ;
  inherit (channels.yubico-piv-tool-pr-161198)
    yubico-piv-tool
    ;

  haskellPackages = prev.haskellPackages.override
    (old: {
      overrides = prev.lib.composeExtensions (old.overrides or (_: _: { })) (hfinal: hprev:
        let version = prev.lib.replaceChars [ "." ] [ "" ] prev.ghc.version;
        in
        {
          # same for haskell packages, matching ghc versions
          inherit (channels.latest.haskell.packages."ghc${version}")
            haskell-language-server;
        });
      });

}
