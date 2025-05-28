{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      {
        plugin = tmux-thumbs;
        extraConfig = ''
          set -g @thumbs-key 'F'
          set -g @thumbs-regexp-1 '[A-Za-z]\[[^\]]*\]' # Regex for node groups
          set -g @thumbs-regexp-2 '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' # Regex for ISO date format
          set -g @thumbs-contrast 1
        '';
      }
      {
        plugin = extrakto;
        extraConfig = ''
          set -g @extrakto_copy_key "ctrl-p"
          set -g @extrakto_insert_key "enter"
        '';
      }
      yank
      prefix-highlight
      tmux-nova
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-Space";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Enable full mouse support
      set -g mouse on

      # Start index of window/pane with 1, because we're humans, not computers
      set -g base-index 1
      setw -g pane-base-index 1

      set -g renumber-windows on    # renumber windows when a window is closed

      # Prefer vi style key table
      setw -g mode-keys vi

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default key bindings, we're going to override
      unbind C-b
      unbind "\$" # rename-session
      unbind ,    # rename-window
      unbind %    # split-window -h
      unbind '"'  # split-window
      unbind \}    # swap-pane -D
      unbind \{    # swap-pane -U
      unbind [    # paste-buffer
      unbind ]
      unbind "'"  # select-window
      unbind n    # next-window
      unbind p    # previous-window
      unbind l    # last-window
      unbind M-n  # next window with alert
      unbind M-p  # next window with alert
      unbind o    # focus thru panes
      unbind &    # kill-window
      unbind "#"  # list-buffer
      unbind =    # choose-buffer
      unbind z    # zoom-pane
      unbind M-Up  # resize 5 rows up
      unbind M-Down # resize 5 rows down
      unbind M-Right # resize 5 rows right
      unbind M-Left # resize 5 rows left
      unbind -
      unbind _

      # new window and retain cwd
      bind c new-window -c "#{pane_current_path}"

      # Split panes
      bind _ split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Select pane and windows
      bind -r C-h previous-window
      bind -r C-l next-window
      bind -r [ select-pane -t :.-
      bind -r ] select-pane -t :.+
      bind -r l last-window   # cycle thru MRU tabs
      bind -r C-Space switch-client -l
      bind -r C-o swap-pane -D
      bind -r C-i swap-pane -U

      # Kill pane/window/session shortcuts
      bind x kill-pane
      bind X kill-window
      bind C-x confirm-before -p "kill other windows? (y/n)" "kill-window -a"
      bind Q confirm-before -p "kill-session #S? (y/n)" kill-session

      # Detach from session
      bind d detach
      bind D if -F '#{session_many_attached}' \
          'confirm-before -p "Detach other clients? (y/n)" "detach -a"' \
          'display "Session has only 1 client attached"'

      bind p paste-buffer
      bind P choose-buffer

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # # Smart pane switching with awareness of Vim splits.
      # # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      # is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      #   | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      # bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      # bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      # bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      # bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      # tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      # if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
      #   "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      # if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
      #   "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      # trigger copy mode by
      bind Enter copy-mode
      run -b 'tmux bind -t vi-copy v begin-selection 2> /dev/null || true'
      run -b 'tmux bind -T copy-mode-vi v send -X begin-selection 2> /dev/null || true'
      run -b 'tmux bind -t vi-copy C-v rectangle-toggle 2> /dev/null || true'
      run -b 'tmux bind -T copy-mode-vi C-v send -X rectangle-toggle 2> /dev/null || true'
      run -b 'tmux bind -t vi-copy y copy-selection 2> /dev/null || true'
      run -b 'tmux bind -T copy-mode-vi y send -X copy-selection-and-cancel 2> /dev/null || true'
      run -b 'tmux bind -t vi-copy Escape cancel 2> /dev/null || true'
      run -b 'tmux bind -T copy-mode-vi Escape send -X cancel 2> /dev/null || true'
      run -b 'tmux bind -t vi-copy H start-of-line 2> /dev/null || true'
      run -b 'tmux bind -T copy-mode-vi H send -X start-of-line 2> /dev/null || true'
      run -b 'tmux bind -t vi-copy L end-of-line 2> /dev/null || true'
      run -b 'tmux bind -T copy-mode-vi L send -X end-of-line 2> /dev/null || true'

      # Scroll up/down by 1 line, half screen, whole screen
      bind -T copy-mode-vi M-Up              send-keys -X scroll-up
      bind -T copy-mode-vi M-Down            send-keys -X scroll-down
      bind -T copy-mode-vi M-PageUp          send-keys -X halfpage-up
      bind -T copy-mode-vi M-PageDown        send-keys -X halfpage-down
      bind -T copy-mode-vi PageDown          send-keys -X page-down
      bind -T copy-mode-vi PageUp            send-keys -X page-up

      # Open find-session prompt
      bind C-f command-prompt -p find-session 'switch-client -t %%'

      # general status bar settings
      set -g status on
      set -g status-interval 5
      set -g status-justify centre
      set -g status-right-length 100
      set -g status-position bottom
    '';
  };

}
