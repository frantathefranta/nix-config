{
  buildGoModule,
  fetchFromGitHub,
  lib,
  symlinkJoin,
}:
let
  generic =
    { modRoot, vendorHash }:
    buildGoModule rec {
      pname = "bird-lg-${modRoot}";
      version = "master";

      src = fetchFromGitHub {
        owner = "frantathefranta";
        repo = "bird-lg-go";
        rev = "536ab04fe9e76b85c951a6decbab8e61842c7bea";
        hash = "sha256-EfomfU95cK2IaSWeCiLxNNz8c1yiJ6FGEzNBIHYDbHU=";
      };

      doDist = false;

      ldflags = [
        "-s"
        "-w"
      ];

      inherit modRoot vendorHash;

      meta = {
        description = "Bird Looking Glass";
        homepage = "https://github.com/xddxdd/bird-lg-go";
        # changelog = "https://github.com/xddxdd/bird-lg-go/releases/tag/v${version}";
        license = lib.licenses.gpl3Plus;
        maintainers = with lib.maintainers; [
          tchekda
          e1mo
        ];
      };
    };

  bird-lg-frontend = generic {
    modRoot = "frontend";
    vendorHash = "sha256-kNysGHtOUtYGHDFDlYNzdkCXGUll105Triy4UR7UP0M=";
  };

  bird-lg-proxy = generic {
    modRoot = "proxy";
    vendorHash = "sha256-iosWHHeJyqMPF+Y01+mj70HDKWw0FAZKDpEESAwS/i4=";
  };
in
symlinkJoin {
  pname = "bird-lg-custom";
  inherit (bird-lg-frontend) version meta;
  paths = [
    bird-lg-frontend
    bird-lg-proxy
  ];
}
