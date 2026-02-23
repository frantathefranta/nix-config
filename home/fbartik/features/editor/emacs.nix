{
  pkgs,
  config,
  lib,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  emacsBase =
    if isDarwin then
      pkgs.emacs
    else if (builtins.length config.monitors != 0) then
      pkgs.emacs-gtk
    else
      pkgs.emacs-nox;
  emacs =
    with pkgs;
    (emacsPackagesFor emacsBase).emacsWithPackages (
      epkgs: with epkgs; [
        treesit-grammars.with-all-grammars
        vterm
        mu4e
        pbcopy
      ]
    );
  /*
    home-manager doesn't seem to build Emacs Client.app yet (only Emacs.app) so this is a substitute for that.
    Let's see if it breaks in newer versions
  */
  emacsClientPlist = pkgs.writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleAllowMixedLocalizations</key>
        <true/>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleDisplayName</key>
        <string>Emacs Client</string>
        <key>CFBundleDocumentTypes</key>
        <array>
            <dict>
                <key>CFBundleTypeName</key>
                <string>Text Document</string>
                <key>CFBundleTypeRole</key>
                <string>Editor</string>
                <key>LSItemContentTypes</key>
                <array>
                    <string>public.text</string>
                    <string>public.plain-text</string>
                    <string>public.source-code</string>
                    <string>public.script</string>
                    <string>public.shell-script</string>
                    <string>public.data</string>
                </array>
            </dict>
        </array>
        <key>CFBundleExecutable</key>
        <string>droplet</string>
        <key>CFBundleGetInfoString</key>
        <string>Emacs Client ${emacsBase.version}</string>
        <key>CFBundleIconFile</key>
        <string>applet</string>
        <key>CFBundleIconName</key>
        <string>droplet</string>
        <key>CFBundleIdentifier</key>
        <string>org.gnu.EmacsClient</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>Emacs Client</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>${emacsBase.version}</string>
        <key>CFBundleSignature</key>
        <string>dplt</string>
        <key>CFBundleURLTypes</key>
        <array>
            <dict>
                <key>CFBundleURLName</key>
                <string>Org Protocol</string>
                <key>CFBundleURLSchemes</key>
                <array>
                    <string>org-protocol</string>
                </array>
            </dict>
        </array>
        <key>CFBundleVersion</key>
        <string>${emacsBase.version}</string>
        <key>LSApplicationCategoryType</key>
        <string>public.app-category.productivity</string>
        <key>LSMinimumSystemVersionByArchitecture</key>
        <dict>
            <key>x86_64</key>
            <string>10.6</string>
        </dict>
        <key>LSRequiresCarbon</key>
        <true/>
        <key>NSAppleEventsUsageDescription</key>
        <string>This script needs to control other applications to run.</string>
        <key>NSAppleMusicUsageDescription</key>
        <string>This script needs access to your music to run.</string>
        <key>NSCalendarsUsageDescription</key>
        <string>This script needs access to your calendars to run.</string>
        <key>NSCameraUsageDescription</key>
        <string>This script needs access to your camera to run.</string>
        <key>NSContactsUsageDescription</key>
        <string>This script needs access to your contacts to run.</string>
        <key>NSHomeKitUsageDescription</key>
        <string>This script needs access to your HomeKit Home to run.</string>
        <key>NSHumanReadableCopyright</key>
        <string>Copyright © 1989-2026 Free Software Foundation, Inc.</string>
        <key>NSMicrophoneUsageDescription</key>
        <string>This script needs access to your microphone to run.</string>
        <key>NSPhotoLibraryUsageDescription</key>
        <string>This script needs access to your photos to run.</string>
        <key>NSRemindersUsageDescription</key>
        <string>This script needs access to your reminders to run.</string>
        <key>NSSiriUsageDescription</key>
        <string>This script needs access to Siri to run.</string>
        <key>NSSystemAdministrationUsageDescription</key>
        <string>This script needs access to administer this system to run.</string>
        <key>OSAAppletShowStartupScreen</key>
        <false/>
    </dict>
    </plist>
  '';
  emacsClientApp = pkgs.runCommand "emacs-client-app" { } ''
    mkdir -p "$out/Applications/Emacs Client.app/Contents/MacOS"
    mkdir -p "$out/Applications/Emacs Client.app/Contents/Resources"
    cp ${emacsClientPlist} "$out/Applications/Emacs Client.app/Contents/Info.plist"
    cp ${./applet.icns} "$out/Applications/Emacs Client.app/Contents/Resources/applet.icns"
    cat > "$out/Applications/Emacs Client.app/Contents/MacOS/droplet" << EOF
    #!/bin/sh
    exec ${emacs}/bin/emacsclient -c -n "\$@"
    EOF
    chmod +x "$out/Applications/Emacs Client.app/Contents/MacOS/droplet"
  '';
in
{
  programs.emacs = {
    enable = true;
    package = emacs;
  };
  services.emacs = {
    enable = true;
    defaultEditor = true;
  };
  home.packages =
    with pkgs;
    [
      # For installing LSP servers
      ispell # Spelling
      # :tools editorconfig
      editorconfig-core-c # per-project style config
      # :tools lookup & :lang org +roam
      sqlite
      nil
      nixd # Nix LSP
      mu.mu4e # Mail
      python3Minimal
      emacs-lsp-booster
      aporetic # fonts
      imagemagick
      pinentry-emacs
    ]
    ++ lib.optionals isDarwin [ emacsClientApp ]
    ++ lib.optionals (!isDarwin) [
      xclip
      nodePackages.npm # This takes hours to build, might need to add it as a brew cask?
    ];
}
