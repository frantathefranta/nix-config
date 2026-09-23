{
  pkgs,
  ...
}:

{
  imports = [ ./packages ];
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [
      pkgs.python3
    ];
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
      defaultProvider = "openwebui";
      enabledModels = [
        "openwebui/qwen3.8-27b-fp8"
        "openwebui/qwen35-122b-fp8"
        "openai-codex/gpt-5.6-sol"
        "openai-codex/gpt-5.6-terra"
        "openai-codex/gpt-5.6-luna"
        "openai-codex/gpt-6-sol"
        "openai-codex/gpt-6-terra"
        "openai-codex/gpt-6-luna"
      ];
    };
  };
  home.sessionVariables = {
    PI_SKIP_VERSION_CHECK = true;
    PI_TELEMETRY = false;
    OPENWEBUI_BASE_URL = "https://pzs0708.ai-alpha.osc.edu/api";
  };
  home.packages = [
    pkgs.pi-acp
  ];
}
