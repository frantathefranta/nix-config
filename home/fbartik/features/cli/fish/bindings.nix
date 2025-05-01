{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.fish = {
    interactiveShellInit = ''
      fish_vi_key_bindings
      set fish_cursor_default     block      blink
      set fish_cursor_insert      line       blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual      block

      bind -M insert \cp up-or-search
      bind -M insert \cn down-or-search
      bind -M insert \cj accept-autosuggestion
    '';
  };
}
