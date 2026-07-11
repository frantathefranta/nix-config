{ isStableHM, ... }:
{
  programs.fzf = {
    enable = true;
    defaultOptions = [ "--color 16" ];
  } // (if isStableHM then { } else { historyWidget.command = ""; });
}
