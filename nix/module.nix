# Home Manager module. Both applications read a theme out of ~/.config, so the whole of the
# integration is a file and the setting that names it — but the setting is what a consumer keeps
# getting wrong, and it differs per application, so there is a switch for each
{ self }:
{
  config,
  lib,
  ...
}:

let
  cfg = config.ddlc;

  variant = lib.types.enum [
    "light"
    "dark"
  ];
in
{
  options.ddlc = {
    kitty = {
      enable = lib.mkEnableOption "the DDLC kitty colours";

      variant = lib.mkOption {
        type = variant;
        default = "dark";
        description = "Which variant kitty is set in";
      };
    };

    btop = {
      enable = lib.mkEnableOption "the DDLC btop theme";

      variant = lib.mkOption {
        type = variant;
        default = "dark";
        description = ''
          Which variant btop is set in. Both are deployed either way — btop lists whatever is
          in its themes directory, so the other one is a keypress away in its own menu
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.kitty.enable {
      # Colours land after settings in kitty.conf, and kitty takes the last word for a key —
      # so this wins over anything the rest of the configuration sets
      programs.kitty.extraConfig = lib.mkAfter (
        builtins.readFile self.lib.kitty.${cfg.kitty.variant}
      );
    })

    (lib.mkIf cfg.btop.enable {
      # The file name is the theme name, so the app segment is dropped on the way in
      xdg.configFile = {
        "btop/themes/ddlc-light.theme".source = self.lib.btop.light;
        "btop/themes/ddlc-dark.theme".source = self.lib.btop.dark;
      };

      programs.btop.settings.color_theme = lib.mkDefault "ddlc-${cfg.btop.variant}";
    })
  ];
}
