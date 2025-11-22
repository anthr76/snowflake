{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "scuttle";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "poseidon";
    repo = "scuttle";
    rev = "v${version}";
    hash = "sha256-9KCoOK5BQqSUmbDsw+hYhbADaCeuPDbheIgCQ0xX1Eg=";
  };

  vendorHash = "sha256-RLikbivRVGD3yYqmmzPPUaj3qs5xY5SHn47W3bDdILU=";

  subPackages = ["cmd/scuttle"];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "Kubelet graceful node drain/delete and spot termination watcher";
    homepage = "https://github.com/poseidon/scuttle";
    license = licenses.mpl20;
    maintainers = [];
    mainProgram = "scuttle";
  };
}
