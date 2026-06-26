{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "led_matrix_monitoring";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "night-crawler";
    repo = "led_matrix_monitoring";
    rev = "${version}";
    hash = "sha256-jZMV5UfYpoNuXqcfXFsxXXlbY+M3R5UNY2aT1BJFiG4=";
  };

  cargoHash = "sha256-seibG75kJ/2MAdpLgHEZCBl51OaYKKG78oBQ0+1ac3I=";

  # requires nightly features
  env.RUSTC_BOOTSTRAP = 1;
  env.RUSTFLAGS = "--cfg tokio_unstable --cfg=tokio_unstable";
  doCheck = false;

  meta = {
    description = "Renders metrics on Framework 16 LED Matrix via daemon";
    changelog = "https://github.com/night-crawler/led_matrix_monitoring";
    homepage = "https://github.com/night-crawler/led_matrix_monitoring";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      anthr76
    ];
    mainProgram = "led_matrix_monitoring";
  };
}
