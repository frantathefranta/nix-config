{
  lib,
  buildGoModule,
  fetchFromGitLab,
}:
buildGoModule (finalAttrs: {
  pname = "varroa";
  version = "master";

  src = fetchFromGitLab {
    owner = "passelecasque";
    repo = "varroa";
    # tag = "${finalAttrs.version}";
    rev = "7a4f8474a96f564fa8d2609f2c99725d1353ca79";
    hash = "sha256-DgaZQgg8QX/1cJSYfvZuf9gqQvS2HtIlKkOAqrU4pfY=";
  };

  vendorHash = "sha256-CRZRC4z/uVbhEUy7fSwBtIlqaKWWVj5zgo5R3zI6cx4=";

  preCheck = ''
    ln -s $PWD ../varroa
  '';

  doCheck = true;

  # passthru = {
  #   updateScript = nix-update-script { };
  #   tests.version = testers.testVersion {
  #     package = finalAttrs.finalPackage;
  #     command = "wrtag --version";
  #   };
  # };

  meta = {
    description = "A much nicer parasite than varroa destructor.";
    homepage = "https://gitlab.com/passelecasque/varroa";
    # license = lib.licenses.gpl3Only;
    mainProgram = "varroa";
  };
})
