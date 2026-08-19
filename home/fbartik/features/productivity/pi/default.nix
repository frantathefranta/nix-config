{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./packages ];
  programs.pi-coding-agent = {
    enable = true;
    context = ./context.md;
    settings = {
      compaction = {
        enabled = true;
        keepRecentTokens = 20000;
        reserveTokens = 16384;
      };
      enableInstallTelemetry = false;
      extensions = [ ./extensions ];
      skills = [ ./skills ];
      enabledModels = [
        "openwebui/qwen3-coder-next"
        "openwebui/qwen35-122b-fp8"
        "openwebui/gpt-oss-120b"
        "openwebui/qwen36-fp8"
        "anthropic/claude-opus-4-8"
        "anthropic/claude-opus-5"
        "anthropic/claude-sonnet-5"
      ];
    };
  };
  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = true;
    PI_TELEMETRY = false;
  };
}
