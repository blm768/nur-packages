{ lib
, fetchFromGitHub
, pkgs
, rustPlatform
}:

rustPlatform.buildRustPackage {
  pname = "display-switch";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "haimgel";
    repo = "display-switch";
    rev = "4b1cbf0baf7bc66b427074a0c0985ecd17f8f759";
    sha256 = "sha256-irNX2z3lc6HgdpRz1B+jCmMn5i5MTYRQAOUbZG7BGq8=";
  };
  patches = [ ./fix-test.patch ];

  cargoSha256 = "sha256-TPqEDbu9X5gBf4WVOUnDEmUbdl9JR8ewTU/sRyZG1FU=";

  buildInputs = with pkgs; [ udev ];
  nativeBuildInputs = with pkgs; [ pkg-config ];

  meta = with lib; {
    homepage = "https://github.com/haimgel/display-switch";
    description = "Turn a USB switch into a full-featured multi-monitor KVM switch";
    license = licenses.mit;
    # TODO: add mantainer entry once I've got one in nixpkgs
    # maintainers = with maintainers; [ blm768 ];
  };
}
