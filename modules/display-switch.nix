{ config , lib , pkgs , ... }:

let
  cfg = config.services.display-switch;
  # Common options between the global and per-display configurations
  connectionOptions = let types = lib.types; in {
    onUsbConnect = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Hdmi1";
      description = "The input to choose when the USB device is connected.";
    };
    onUsbDisconnect = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "Hdmi1";
      description = "The input to choose when the USB device is disconnected.";
    };
    onUsbConnectExecute = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "echo connected";
      description = "A command to run when the USB device is connected.";
    };
    onUsbDisconnectExecute = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "echo disconnected";
      description = "A command to run when the USB device is disconnected.";
    };
    extraConfig = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Extra configuration options.";
    };
  };
  mkConnectionCfg = opts:
    (lib.attrsets.filterAttrs
      (k: v: v != null)
      {
        on_usb_connect = opts.onUsbConnect;
        on_usb_disconnect = opts.onUsbDisconnect;
        on_usb_connect_execute = opts.onUsbConnectExecute;
        on_usb_disconnect_execute = opts.onUsbDisconnectExecute;
      }) // opts.extraConfig;
  mkMonitorCfg = opts: { monitor_id = opts.monitorId; } // (mkConnectionCfg opts);
in {
  options = let types = lib.types; in {
    services.display-switch = {
      enable = lib.mkEnableOption (lib.mdDoc ''
        Enable display-switch.
        Automatically updates monitor inputs based on USB connections.
      '');

      usbDevice = lib.mkOption {
        type = types.str;
        example = "1050:0407";
        description = "The USB device that will trigger display changes.";
      };

      monitors = lib.mkOption {
        type = types.attrsOf (types.submodule {
            options = {
              monitorId = lib.mkOption {
                type = types.str;
                example = "dell";
                description = "A case-insensitive string to match against the monitor description.";
              };
            } // connectionOptions;
          });
        default = {};
        description = "Per-monitor input configuration.";
      };
    } // connectionOptions;
  };

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "display-switch/display-switch.ini".text = lib.generators.toINIWithGlobalSection {} {
          globalSection = {
            usb_device = cfg.usbDevice;
          } // (mkConnectionCfg cfg);
          sections = builtins.mapAttrs (k: v: (mkMonitorCfg v)) cfg.monitors;
        };
    };

    systemd.services.display-switch = {
      enable = true;
      # Kind of a hack, but display-switch assumes it's run as a "regular" user,
      # so we need to trick it into loading system-level config files.
      environment = {
        XDG_CONFIG_HOME = "/etc";
        # Only used for logging as of 1.2.0
        XDG_DATA_HOME = "/var/log";
      };
      serviceConfig = {
        ExecStart = "${pkgs.nur.repos.blm768.display-switch}/bin/display_switch";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  meta = {
    maintainers = with lib.maintainers; [ blm768 ];
  };
}
