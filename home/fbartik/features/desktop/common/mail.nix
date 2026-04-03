# Inspiration for mu4e configuration came from https://github.com/danielfleischer/mu4easy
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

  commonMsmtp = {
    enable = true;
    extraConfig = {
      logfile = "~/.cache/msmtp/msmtp.log";
    };
  };

  mkImapnotify = account: {
    enable = true;
    boxes = [ "INBOX" ];
    onNotify = "${pkgs.isync}/bin/mbsync ${account}";
    onNotifyPost = ''
      ${pkgs.emacs}/bin/emacsclient -e '(mu4e-update-index)'
    '';
  };

  # Shared extraConfig for each channel inside gmail-fb's groups.
  gmailChannelExtra = {
    SyncState = "*";
    CopyArrivalDate = "yes";
    Create = "both";
    Expunge = "both";
  };

  mkGmailChannel = far: near: {
    farPattern = far;
    nearPattern = near;
    extraConfig = gmailChannelExtra;
  };
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
          extraConfig.channel.CopyArrivalDate = "yes";
          groups."icloud".channels = {
            "all" = {
              patterns = [
                "INBOX"
                "Archive"
                "Deleted Messages"
                "Junk"
                "Drafts"
              ];
              extraConfig = {
                SyncState = "*";
                CopyArrivalDate = "yes";
                Create = "both";
                Expunge = "both";
              };
            };
            "sent" = {
              farPattern = "Sent Messages";
              nearPattern = "Sent";
              extraConfig = {
                SyncState = "*";
                CopyArrivalDate = "yes";
                Create = "both";
                Expunge = "both";
              };
            };
          };

        };
        msmtp = commonMsmtp;
        imapnotify = mkImapnotify "icloud";
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
        flavor = "gmail.com";
        folders = {
          inbox = "Inbox";
          sent = "[Gmail]/Sent Mail";
          trash = "[Gmail]/Trash";
          drafts = "[Gmail]/Drafts";
        };
        mu.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "maildir";
          remove = "both";
          groups."gmail-oz".channels = {
            inbox = mkGmailChannel "INBOX" "INBOX";
            trash = mkGmailChannel "[Gmail]/Trash" "Trash";
            spam = mkGmailChannel "[Gmail]/Spam" "Spam";
            all = mkGmailChannel "[Gmail]/All Mail" "Archive";
            drafts = mkGmailChannel "[Gmail]/Drafts" "Drafts";
          };
        };
        msmtp = commonMsmtp;
        imapnotify = mkImapnotify "gmail-oz";
      };
      gmail-fb = {
        primary = false;
        realName = realName;
        address = "frantabart@gmail.com";
        userName = "frantabart@gmail.com";
        passwordCommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."email/gmail-fb".path}";
        flavor = "gmail.com";
        folders = {
          inbox = "Inbox";
          sent = "[Gmail]/Sent Mail";
          trash = "[Gmail]/Trash";
          drafts = "[Gmail]/Drafts";
        };
        mu.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "maildir";
          remove = "both";
          groups."gmail-fb".channels = {
            inbox = mkGmailChannel "INBOX" "INBOX";
            trash = mkGmailChannel "[Gmail]/Trash" "Trash";
            spam = mkGmailChannel "[Gmail]/Spam" "Spam";
            all = mkGmailChannel "[Gmail]/All Mail" "Archive";
            drafts = mkGmailChannel "[Gmail]/Drafts" "Drafts";
          };
        };
        msmtp = commonMsmtp;
        imapnotify = mkImapnotify "gmail-fb";
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
