{
  services.evremap = {
    enable = true;
    settings = {
      device_name = "AT Translated Set 2 keyboard";
      dual_role = [
        {
          hold = [
            "KEY_LEFTCTRL"
          ];
          input = "KEY_CAPSLOCK";
          tap = [
            "KEY_ESC"
          ];
        }
        # Tried to implement home-row mods but it doesn't have adjustable timeout
        # {
        #   input = "KEY_A";
        #   tap = [
        #     "KEY_A"
        #   ];
        #   hold = [
        #     "KEY_LEFTMETA"
        #   ];
        # }
        # {
        #   input = "KEY_S";
        #   tap = [
        #     "KEY_S"
        #   ];
        #   hold = [
        #     "KEY_LEFTALT"
        #   ];
        # }
        # {
        #   input = "KEY_D";
        #   tap = [
        #     "KEY_D"
        #   ];
        #   hold = [
        #     "KEY_LEFTCTRL"
        #   ];
        # }
        # {
        #   input = "KEY_F";
        #   tap = [
        #     "KEY_F"
        #   ];
        #   hold = [
        #     "KEY_LEFTSHIFT"
        #   ];
        # }

      ];
    };
  };
}
