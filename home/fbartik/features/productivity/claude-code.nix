{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.unstable.claude-code;
    settings = {
      sandbox = {
        enabled = true;
        filesystem = {
          allowRead = [ "." ];
          denyRead = [ "~/" ];
          allowWrite = [ "." ];
          denyWrite = [ "/" ];
        };
      };
    };
  };
}
