# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  pkgs-stable,
  ...
}@inputs:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # overlays
  nixpkgs.overlays = [ inputs.neorg-overlay.overlays.default ];

  # Bootloader
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
    grub = {
      # despite what the configuration.nix manpage seems to indicate,
      # as of release 17.09, setting device to "nodev" will still call
      # `grub-install` if efiSupport is true
      # (the devices list is not used by the EFI grub install,
      # but must be set to some value in order to pass an assert in grub.nix)
      devices = [ "nodev" ];
      efiSupport = true;
      configurationLimit = 8;
      enable = true;
      # set $FS_UUID to the UUID of the EFI partition
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root 9041-0C58
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  services = {
    syncthing = {
      enable = true;
      user = "benlubas";
      dataDir = "/home/benlubas/notes"; # Default folder for new synced folders
      configDir = "/home/benlubas/.config/syncthing";
      overrideDevices = true; # overrides any devices added or deleted through the WebUI
      overrideFolders = true; # overrides any folders added or deleted through the WebUI
      settings = {
        devices = {
          "s22" = {
            id = "ZIV6ZCV-XOOJHCB-UOQXICZ-H22CH3E-T4C6YJH-674JDUM-4QXN7YV-25ALWQT";
          };
          "MacBookAir" = {
            id = "UAHJ72Y-GFBAEJD-EJ22EZS-X6T3FRI-2GPTNNM-JWBSZG4-ROCFHMI-RWJCNAZ";
          };
        };
        folders = {
          "Notes" = {
            # Name of folder in Syncthing, also the folder ID
            path = "/home/benlubas/notes"; # Which folder to add to Syncthing
            devices = [ "s22" ]; # Which devices to share the folder with
          };
        };
      };
    };
  };

  networking.hostName = "nixos"; # Define your hostname
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    # Configure keymap in X11
    xkb = {
      variant = "";
      layout = "us";
    };

    desktopManager = {
      xterm.enable = false;
    };

    autoRepeatDelay = 250;
    autoRepeatInterval = 22;
    displayManager = {
      lightdm = {
        enable = true;
      };
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs-stable; [
        rofi # application launcher
        i3lock # default i3 screen locker
        polybar
      ];
    };
  };

  services.libinput = {
    enable = true;
    mouse.accelProfile = "flat"; # disabling mouse acceleration
  };

  services.displayManager = {
    defaultSession = "none+i3";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs.zsh.enable = true;

  users.defaultUserShell = pkgs.zsh;

  ### gaming settings ###
  programs.steam.enable = true;
  # This \/ requires more finikey commands, and I'm not sure how much performance I would get out of
  # it.
  # programs.steam.gamescopeSession.enable = true;
  # NOTE: requires "gamemoderun %command%" as `run args` in steam (for each game)
  programs.gamemode.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.benlubas = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Ben Lubas";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "uucp"
    ];
    packages =
      with pkgs;
      # unstable packages:
      [
        lua51Packages.nlua
        blender
        brave
        btop
        gh
        google-chrome
        heroic
        kitty
        pandoc
        qmk
        typst
        wine
        # wine64
      ]
      ++
        # stable packages
        (with pkgs-stable; [
          anki
          dict
          ffmpeg_6-full
          flameshot
          fontforge-gtk
          discord
          gimp
          globalprotect-openconnect
          imagemagick
          inkscape
          iruby
          lazygit
          losslesscut-bin
          neofetch
          mermaid-cli
          numbat
          obs-studio
          prismlauncher
          quarto
          sccache
          sqlite
          vlc
          vmware-horizon-client
          wine64
        ]);
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # to let dynamically linked libs to work
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs here, NOT in environment.systemPackages
    # list taken from: https://github.com/Mic92/dotfiles/blob/393539385b0abfc3618e886cd0bf545ac24aeb67/machines/modules/nix-ld.nix#L4
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    fuse3
    gdk-pixbuf
    glib
    gtk3
    icu
    libGL
    libappindicator-gtk3
    libdrm
    libglvnd
    libnotify
    libpulseaudio
    libunwind
    libusb1
    libuuid
    libxkbcommon
    libxml2
    mesa
    nspr
    nss
    openssl
    pango
    pipewire
    stdenv.cc.cc
    systemd
    vulkan-loader
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
    zlib
  ];

  # install flatpack (for flatpack discord)
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-kde ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment.systemPackages =
    with pkgs-stable;
    let
      R-with-packages = rWrapper.override {
        packages = with rPackages; [
          xml2
          lintr
          roxygen2
          languageserver
        ];
      };
    in
    [
      # STABLE PACKAGES
      R
      R-with-packages
      appimage-run
      bat
      cinnamon.nemo # gui file browser
      clang
      clang-tools_9
      curl
      dunst
      efibootmgr
      exfatprogs
      feh
      fnm
      fzf
      gcc
      gdb
      git
      gnumake
      go
      gparted
      jdk17
      jq
      killall
      libcxxStdenv
      libstdcxx5
      libusb1
      nodejs
      ntfs3g
      openssl
      python3
      quickemu
      ripgrep
      stdenv
      texlive.combined.scheme-full
      tty-clock
      unzip
      valgrind
      wget
      xclip
      zig

      (inputs.plover-flake.packages.${pkgs.system}.plover.with-plugins (
        ps: with ps; [ plover-lapwing-aio ]
      ))

      inputs.ghostty.packages.x86_64-linux.default
    ]
    ++ (with pkgs; [
      # UNSTABLE PACKAGES
      tmux
      steam-run
      rustup
      jujutsu
      firefox
      fd
      direnv
      delta
      cargo
    ]);

  fonts.packages =
    let
      lafayette-mono-font = inputs.lafayette-mono.packages.${pkgs.system}.default;
      op-mono-font = inputs.op-mono.packages.${pkgs.system}.default;
    in
    [
      (pkgs-stable.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      lafayette-mono-font
      op-mono-font
      pkgs-stable.roboto
    ];

  # Enable OpenGL
  # required for: kitty
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Do not disable this unless your GPU is unsupported or if you have a good reason to.
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
