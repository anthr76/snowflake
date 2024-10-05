{
  fetchurl,
  python3,
  stdenv,
  mpv,
  ffmpeg,
  lib,
  gettext
}:

stdenv.mkDerivation rec {
  pname = "yuki-iptv";
  version = "0.0.13";

  src = fetchurl {
    url = "https://codeberg.org/liya/yuki-iptv/archive/${version}.tar.gz";
    sha256 = "8d1858f8bcd5908f58daab2231ef6d0beb25e0003c6197e86ed39a32670e2308";
  };

  buildInputs = [
    python3
    mpv
    ffmpeg
  ];

  nativeBuildInputs = [
    python3.pkgs.wrapPython
    gettext
  ];

  pythonPath = with python3.pkgs; [
    pyqt6
    pillow
    pygobject3
    unidecode
    requests
    chardet
    setproctitle
    wand
    sip
  ];

  preBuild = ''
    # Replace version in About dialog
    sed -i "s/__DEB_VERSION__/${version}/g" usr/lib/yuki-iptv/yuki-iptv.py
  '';

  postPatch = ''
    substituteInPlace usr/lib/yuki-iptv/yuki-iptv.py \
      --replace __DEB_VERSION__ ${version}

  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out

    runHook postInstall
  '';

  preFixup = ''
    buildPythonPath "$out $pythonPath"

    wrapProgram $out/bin/yuki-iptv \
      --prefix PYTHONPATH : "$program_PYTHONPATH"
  '';

  meta = with lib; {
    description = "IPTV player with EPG support";
    license = licenses.gpl3;
    platforms = platforms.all;
    homepage = "https://codeberg.org/liya/yuki-iptv";
  };
}
