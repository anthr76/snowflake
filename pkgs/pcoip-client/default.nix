{ fetchurl, lib, stdenv, buildPackages, makeWrapper, runCommand }:

with lib;

let
  pkgname = "pcoip-client";
  pkgver = "23.01.1";
  ubuntuver = "20.04";
  boostver = "1.71.0";
  majorboostver = "1.71";
  boostfilesuffix = "${boostver}_${boostver}-6ubuntu6_amd64.deb";
  protobufver = "17";
  libprotobufver = "3.6.1.3-2ubuntu5";
  libhiredisver = "0.14.1-2";
  sources = {
    "${pkgname}_${pkgver}-${ubuntuver}_amd64.deb" = fetchurl {
      url = "https://dl.teradici.com/DeAdBCiUYInHcSTy/pcoip-client/deb/ubuntu/pool/focal/main/p/pc/pcoip-client_${pkgver}-${ubuntuver}/pcoip-client_${pkgver}-${ubuntuver}_amd64.deb";
      sha256 = "9597b67da6a0065b61a942416874f21acf5faa7a6f645ae92316a28a65a84110";
    };
    "libprotobuf${protobufver}_${libprotobufver}_amd64.deb" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/main/p/protobuf/libprotobuf${protobufver}_${libprotobufver}_amd64.deb";
      sha256 = "b78b3d507dd2e70eeef31a703232980401d8f65b10db731b56deb44965482753";
    };
    "libhiredis${libhiredisver}_${libhiredisver}_amd64.deb" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/universe/h/hiredis/libhiredis${libhiredisver}_${libhiredisver}_amd64.deb";
      sha256 = "eb382ba7f1955d111a3b6a70e465d1d8accf995106315b4b9562378c328b411f";
    };
    "libboost-system${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/main/b/boost${majorboostver}/libboost-system${boostfilesuffix}";
      sha256 = "7d4e150855855a2788481f319f4cd9515f526f8fcbf7038a98441d68a8c4c4c1";
    };
    "libboost-thread${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/main/b/boost${majorboostver}/libboost-thread${boostfilesuffix}";
      sha256 = "707045c56ef0141a77f449eed92eca741660ea1857b00a38db228e6038e0ac92";
    };
    "libboost-chrono${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/main/b/boost${majorboostver}/libboost-chrono${boostfilesuffix}";
      sha256 = "4af58d4155189517f447300ee4535cb4db1351cb55802e28cec8c1f13ac108e6";
    };
    "libboost-filesystem${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/main/b/boost${majorboostver}/libboost-filesystem${boostfilesuffix}";
      sha256 = "6793184cc2b8df0da401fdbe78fbf57ac598438177a6af163f99f9f1c14f9eb8";
    };
    "libboost-regex${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/universe/b/boost${majorboostver}/libboost-regex${boostfilesuffix}";
      sha256 = "7160fc29e33b7b191a618ae4b3ae0bc82c30ad5f38d00b82dc6362c9e954e377";
    };
    "libboost-serialization${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/main/b/boost${majorboostver}/libboost-serialization${boostfilesuffix}";
      sha256 = "29a885e9b1353b1bb69c6d067909c689af86c02bf3a108db1b9d56e9cc63343c";
    };
    "libboost-random${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/universe/b/boost${majorboostver}/libboost-random${boostfilesuffix}";
      sha256 = "b5e9691cc94d42b5241293f6ad5bc5438201ed88979520e5604b779cb4da14fa";
    };
    "libboost-container${boostfilesuffix}" = fetchurl {
      url = "http://se.archive.ubuntu.com/ubuntu/pool/universe/b/boost${majorboostver}/libboost-container${boostfilesuffix}";
      sha256 = "992c307928860db9ff7c663c61da1f5545a13ffaa2329a8e111b248138235727";
    };
  };

  makeDerivation = args: buildPackages.stdenv.mkDerivation (args // {
    name = pkgname;
    version = pkgver;
    src = fetchurl {
      url = sources["${pkgname}_${pkgver}-${ubuntuver}_amd64.deb"].url;
      sha256 = sources["${pkgname}_${pkgver}-${ubuntuver}_amd64.deb"].sha256;
    };
    nativeBuildInputs = [ buildPackages.bsdtar buildPackages.patchelf ];
    buildInputs = [
      buildPackages.openssl_1_1
      buildPackages.pcsclite
      buildPackages.qt5-networkauth
      buildPackages.qt5-declarative
      buildPackages.qt5-quickcontrols
      buildPackages.qt5-quickcontrols2
      buildPackages.qt5-graphicaleffects
      buildPackages.qt5-webengine
      buildPackages.glfw
      buildPackages.ffmpeg
    ];
    installPhase = ''
      mkdir -p $out/usr/lib/x86_64-linux-gnu/pcoip-client
      bsdtar -C $out/usr/lib/x86_64-linux-gnu/pcoip-client -xvf $src/data.tar.gz

      # Remove unwanted files and dependencies
      rm -f $out/usr/lib/x86_64-linux-gnu/pcoip-client/org.hp.pcoip-client/vchan_plugins/libvchan-plugin-clipboard.so
      rm -f $out/usr/sbin/pcoip-configure-kernel-networking
      rmdir $out/usr/sbin
      rm -f $out/usr/lib/x86_64-linux-gnu/pcoip-client/libav*
      rm -f $out/usr/lib/x86_64-linux-gnu/pcoip-client/libFlxCo*
      rm -f $out/usr/lib/x86_64-linux-gnu/pcoip-client/libglfw*
      rm -f $out/usr/lib/x86_64-linux-gnu/pcoip-client/libswscale.so*
      rm -rf $out/usr/lib/x86_64-linux-gnu/pcoip-client/wayland
      rm -rf $out/usr/lib/x86_64-linux-gnu/pcoip-client/x11
      rm -rf $out/usr/lib/x86_64-linux-gnu/pcoip-client/pkgconfig
      chmod +x $out/usr/lib/x86_64-linux-gnu/pcoip-client/lib*so*
    '';
  });

in {
  inherit pkgname pkgver;
  nativeBuildInputs = [ buildPackages.fakeroot ];
  inherit makeWrapper;
  inherit runCommand;
  packages = {
    ${pkgname} = makeDerivation {
      buildInputs = buildPackages.stdenv.mkDerivation.buildInputs ++ [ makeWrapper ];
    };
    pcoip-client-clipboard = buildPackages.stdenv.mkDerivation {
      name = "${pkgname}-clipboard";
      nativeBuildInputs = [ buildPackages.bsdtar ];
      src = fetchurl {
        url = sources["${pkgname}_${pkgver}-${ubuntuver}_amd64.deb"].url;
        sha256 = sources["${pkgname}_${pkgver}-${ubuntuver}_amd64.deb"].sha256;
      };
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/usr/lib/x86_64-linux-gnu/org.hp.pcoip-client/vchan_plugins
        bsdtar -C $out/usr/lib/x86_64-linux-gnu/org.hp.pcoip-client/vchan_plugins -xvf $src/data.tar.gz
      '';
    };
  };
}

