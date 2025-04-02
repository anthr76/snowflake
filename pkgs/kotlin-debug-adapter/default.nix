{
  lib,
  stdenv,
  fetchzip,
  openjdk,
  gradle,
  makeWrapper,
  maven,
}:

stdenv.mkDerivation rec {
  pname = "kotlin-debug-adapter";
  version = "0.4.4";
  src = fetchzip {
    url = "https://github.com/fwcd/kotlin-debug-adapter/releases/download/${version}/adapter.zip";
    sha256 = "1f7msyqwnlngkqplm6m3pwd526p3j8azsdxg9n5s6njwc6icdml0";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib
    mkdir -p $out/bin
    cp -r lib/* $out/lib
    cp -r bin/* $out/bin
  '';

  nativeBuildInputs = [
    gradle
    makeWrapper
  ];
  buildInputs = [
    openjdk
    gradle
  ];

  postFixup = ''
    wrapProgram "$out/bin/kotlin-debug-adapter" --set JAVA_HOME ${openjdk} --prefix PATH : ${
      lib.strings.makeBinPath [
        openjdk
        maven
      ]
    }
  '';
}
