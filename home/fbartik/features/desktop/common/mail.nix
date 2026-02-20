{
  config,
  lib,
  pkgs,
  ...
}:
let
  ca-bundle_crt = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  realName = "Franta Bartik";
  primaryEmail = "fb@franta.us";
in
{
  programs = {
    mbsync.enable = true;
    msmtp = {
      enable = true;
      configContent = lib.mkBefore ''
        # Global msmtp configuration
        defaults
        auth on
        tls on
        tls_trust_file ${ca-bundle_crt}

        # Log all transactions
        logfile ${config.home.homeDirectory}/.cache/msmtp/msmtp.log
      '';
    };
    mu.enable = true;
  };

  accounts.email = {
    certificatesFile = ca-bundle_crt;
    maildirBasePath = "${config.home.homeDirectory}/.mail";
    accounts = {
      icloud = {
        primary = true;
        realName = realName;
        address = primaryEmail;
        userName = "frantisek.bartik@icloud.com";
        passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."email/icloud".path}";
        aliases = [ "admin@franta.us" ];
        flavor = "plain";
        folders = {
          inbox = "Inbox";
          trash = "Deleted Messages";
          sent = "Sent Messages";
        };
        mu.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
          extraConfig.channel = {
            CopyArrivalDate = "yes";
          };
        };
        msmtp = {
          enable = true;
          extraConfig = {
            tls_starttls = "on";
            logfile = "~/.cache/msmtp/msmtp.log";
          };
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "${pkgs.isync}/bin/mbsync icloud";
          onNotifyPost = ''
            ${pkgs.emacs}/bin/emacsclient -e '(mu4e-update-index)'
          '';
        };
        imap = {
          host = "imap.mail.me.com";
          tls.enable = true;
          port = 993;
        };
        smtp = {
          host = "smtp.mail.me.com";
          tls.enable = true;
          port = 465;
        };
      };
      gmail-oz = {
        primary = false;
        realName = realName;
        address = "ozzfranta@gmail.com";
        userName = "ozzfranta@gmail.com";
        passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."email/gmail-oz".path}";
        folders = {
          inbox = "Inbox";
          sent = "[Gmail]/Sent Mail";
          trash = "[Gmail]/Trash";
          drafts = "[Gmail]/Drafts";
        };
        flavor = "gmail.com";
        mu.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
          extraConfig.channel = {
            CopyArrivalDate = "yes";
          };
        };
        msmtp = {
          enable = true;
          extraConfig = {
            tls_starttls = "on";
            logfile = "~/.cache/msmtp/msmtp.log";
          };
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "${pkgs.isync}/bin/mbsync gmail-oz";
          onNotifyPost = ''
            ${pkgs.emacs}/bin/emacsclient -e '(mu4e-update-index)'
          '';
        };
      };
      gmail-fb = {
        primary = false;
        realName = realName;
        address = "frantabart@gmail.com";
        userName = "frantabart@gmail.com";
        passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."email/gmail-fb".path}";
        folders = {
          inbox = "Inbox";
          sent = "[Gmail]/Sent Mail";
          trash = "[Gmail]/Trash";
          drafts = "[Gmail]/Drafts";
        };
        flavor = "gmail.com";
        mu.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
          extraConfig.channel = {
            CopyArrivalDate = "yes";
          };
        };
        msmtp = {
          enable = true;
          extraConfig = {
            tls_starttls = "on";
            logfile = "~/.cache/msmtp/msmtp.log";
          };
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "${pkgs.isync}/bin/mbsync gmail-fb";
          onNotifyPost = ''
            ${pkgs.emacs}/bin/emacsclient -e '(mu4e-update-index)'
          '';
        };
      };
    };
  };

  services.imapnotify.enable = true;

  launchd.agents = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "imapnotify-${name}" {
      config = {
        StandardOutPath = "/Users/fbartik/Library/Logs/imapnotify-${name}.log";
        StandardErrorPath = "/Users/fbartik/Library/Logs/imapnotify-${name}.log";
      };
    }
  ) (lib.filterAttrs (_: acc: acc.imapnotify.enable or false) config.accounts.email.accounts);

  sops.secrets."email/icloud" = {
    sopsFile = ../../../NC312237-secrets.yaml;
  };
  sops.secrets."email/gmail-oz" = {
    sopsFile = ../../../NC312237-secrets.yaml;
  };
  sops.secrets."email/gmail-fb" = {
    sopsFile = ../../../NC312237-secrets.yaml;
  };
}
