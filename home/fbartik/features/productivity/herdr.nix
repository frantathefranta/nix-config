{ pkgs, ... }:
{
  programs.herdr = {
    enable = true;
    # Preserve other settings changed in Herdr, while keeping the theme,
    # shell, and keybindings below declarative.
    mutableSettings = true;
    settings = {
      onboarding = false;
      theme = {
        name = "one-dark";
        auto_switch = true;
        dark_name = "one-dark";
        light_name = "one-light";
      };
      terminal = {
        default_shell = "${pkgs.fish}/bin/fish";
        new_cwd = "follow";
      };
      keys = {
        prefix = "ctrl+space";
        previous_workspace = "alt+shift+k";
        next_workspace = "alt+shift+j";
        switch_workspace = "prefix+shift+1..9";
        previous_agent = "prefix+k";
        next_agent = "prefix+j";
        new_tab = "prefix+c";
        previous_tab = "prefix+ctrl+h";
        next_tab = "prefix+ctrl+l";
        split_vertical = "prefix+_"; # Side by side, like tmux split-window -h.
        split_horizontal = "prefix+minus";
        cycle_pane_previous = "prefix+[";
        cycle_pane_next = "prefix+]";
        focus_pane_left = "alt+h";
        focus_pane_down = "alt+j";
        focus_pane_up = "alt+k";
        focus_pane_right = "alt+l";
        copy_mode = "prefix+enter";
        close_pane = "prefix+x";
        close_tab = "prefix+shift+x";
        detach = "prefix+d";
      };
    };
  };
}
