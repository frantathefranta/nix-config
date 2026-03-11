{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "kubectl-passman";
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "chrisns";
    repo = "kubectl-passman";
    rev = "v${version}";
    hash = "sha256-1qR9nlyrE4gXVhzxq4aXcM6lFUVRbQF/3UamPBtb24k=";
  };

  vendorHash = "sha256-vRq67XXuxh24FdFMIhHSIljFGG8qUN8X1aNtWH3wk6A=";

  meta = {
    description = "kubectl plugin that provides the missing link/glue between common password managers and kubectl";
    mainProgram = "kubectl-passman";
    homepage = "https://github.com/chrisns/kubectl-passman";
    changelog = "https://github.com/chrisns/kubectl-passman/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
