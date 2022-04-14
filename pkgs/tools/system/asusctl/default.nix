{ lib, rustPlatform, fetchFromGitLab, pkg-config, libudev}:


  rustPlatform.buildRustPackage rec {
    pname = "asusctl";
    version = "3.7.2";

    src = fetchFromGitLab {
      owner = "asus-linux";
      repo = pname;
      rev = version;
      sha256 = "1486hbs1lnnw9yvj7n7l4lpwsmi0darh94hbw2fwwbsahalkbsr2";
    };

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ libudev ];

    cargoSha256 = "0xd66p3v50g22cqqa56k2g2xakmbg3zfwd9fikh7xwkyj9l0n6ry";

    # doc tests fail
    doCheck = false;

    meta = with lib; {
      description = "A fast line-oriented regex search tool, similar to ag and ack";
      homepage = "https://github.com/BurntSushi/ripgrep";
      license = licenses.unlicense;
      maintainers = [ maintainers.tailhook ];
    };
  }
