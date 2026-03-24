{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:
buildGoModule (finalAttrs: {
  pname = "wrtag-dev";
  version = "master";

  src = fetchFromGitHub {
    owner = "sentriz";
    repo = "wrtag";
    # tag = "${finalAttrs.version}";
    rev = "65a6d3258d7b9cfaac35498dd942b190c2047498";
    hash = "sha256-5/3bw9u2S8Hd7iPjgu0AAT3AkAXMNASEEr9t901AgRI=";
  };

  vendorHash = "sha256-dvbCocOhSzcR/foGGzPibIlQGh7nyE5xHnLCh97YFPg=";

  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion contrib/completions/wrtag.{fish,bash}
    installShellCompletion contrib/completions/metadata.fish
  '';

  # passthru = {
  #   updateScript = nix-update-script { };
  #   tests.version = testers.testVersion {
  #     package = finalAttrs.finalPackage;
  #     command = "wrtag --version";
  #   };
  # };

  meta = {
    description = "Fast automated music tagging and organization based on MusicBrainz";
    longDescription = ''
      wrtag is a music tagging and organisation tool similar to Beets and MusicBrainz Picard.
      Written in go, it aims to be simpler, more composable and faster.
    '';
    homepage = "https://github.com/sentriz/wrtag";
    license = lib.licenses.gpl3Only;
    mainProgram = "wrtag";
  };
})
