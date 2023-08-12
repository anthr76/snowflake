{ lib, stdenv, fetchurl, makeWrapper, file, boost, protobuf, openssl_1_1, icu58, glib, xorg, libGL, libpulseaudio, qt5 }:
let
  libPath = lib.makeLibraryPath [
    boost
    glib
    libGL
    libpulseaudio
    openssl_1_1
    protobuf
    icu58
    stdenv.cc.cc
    xorg.libX11
    qt5.qtbase
    qt5.qtx11extras
    # qt5.qtdeclarative
    qt5.qtxmlpatterns
    qt5.qtscript
  ];
in
stdenv.mkDerivation rec {
  name = "${pname}-${builtins.replaceStrings ["~"] ["-"] version}";
  pname = "teradici-pcoip-client";
  version = "23.01.1";

  src = fetchurl {
    inherit name;
    url = "https://dl.teradici.com/DeAdBCiUYInHcSTy/pcoip-client/deb/ubuntu/pool/jammy/main/p/pc/pcoip-client_23.01.1-22.04/pcoip-client_23.01.1-22.04_amd64.deb";
    sha256 = "u68eZD534jmWjsEI6dvumt4X9Hu0aUyLv5f9wimpkD8=";
  };

  unpackPhase = ''
    ar x $src
    tar xf data.tar.*
  '';

  nativeBuildInputs = [ makeWrapper file ];

  dontBuild = true;


  installPhase = ''
    lib_dir=usr/lib/x86_64-linux-gnu/pcoip-client
    # Get rid of vendored dependencies:
    # =================================
    # We get this one from icu58
    rm -v $lib_dir/libicu*
    # This one we keep because we don't know how to build it (see https://stackoverflow.com/questions/55071459/how-can-i-build-libqt5declarative-so):
    mv $lib_dir/libQt5Declarative.so.* usr/lib
    # The other QT ones we've got:
    rm -rv $lib_dir/libQt5*
    # The QT plugings we've got as well, thanks to the wrapper setting QT_PLUGIN_PATH below:
    rm -rv $lib_dir/plugins
    # The rest appears to be actual Teradici stuff:
    mv -v $lib_dir/* usr/lib
    rm -rv usr/lib/x86_64-linux-gnu
    mv -v usr/libexec/pcoip-client/pcoip-client usr/bin/pcoip-client
    mkdir -p $out
    mv -v usr/bin usr/sbin usr/lib usr/share $out
    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      $out/bin/pcoip-client
    find $out -type f -exec file {} \; |
      grep 'ELF.*shared object' |
      cut -f 1 -d : |
      xargs -d '\n' -n 1 -t -I {} patchelf \
        --set-rpath "$out/lib:${libPath}" {}
    wrapProgram $out/bin/pcoip-client --set QT_PLUGIN_PATH ${qt5.qtbase}/lib/qt-5.6/plugins
  '';

  dontStrip = true;

  meta = {
    homepage = "http://www.teradici.com/web-help/pcoip_client/linux/3.8.1/installation/installing_the_client_overview/";
    license = lib.licenses.unfree;
    description = "Teradici PCoIP Software Client";
    platforms = [ "x86_64-linux" ];
  };
}
