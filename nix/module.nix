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
  # A module is deduplicated by its key, and a function module's key is where it was imported
  # from — so two files importing this one would each declare every option below
  key = "ddlc-themes";

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

    # The three below have no variant switch: each application picks its own. matplotlib names
    # a style per chart, Claude Code lists ~/.claude/themes in /theme, and opencode reads the
    # variant out of the one file by the terminal's own background
    matplotlib = {
      enable = lib.mkEnableOption "the DDLC matplotlib styles and colormaps";
    };

    claude-code = {
      enable = lib.mkEnableOption "the DDLC Claude Code themes";
    };

    opencode = {
      enable = lib.mkEnableOption "the DDLC opencode theme";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.kitty.enable {
      # Colours land after settings in kitty.conf, and kitty takes the last word for a key —
      # so this wins over anything the rest of the configuration sets
      programs.kitty.extraConfig = lib.mkAfter (builtins.readFile self.lib.kitty.${cfg.kitty.variant});
    })

    (lib.mkIf cfg.btop.enable {
      # The file name is the theme name, so the app segment is dropped on the way in
      xdg.configFile = {
        "btop/themes/ddlc-light.theme".source = self.lib.btop.light;
        "btop/themes/ddlc-dark.theme".source = self.lib.btop.dark;
      };

      programs.btop.settings.color_theme = lib.mkDefault "ddlc-${cfg.btop.variant}";
    })

    (lib.mkIf cfg.matplotlib.enable {
      # The filenames are the API — plt.style.use("ddlc"), import ddlc_cmaps — so they keep
      # their source names
      xdg.configFile = {
        "matplotlib/stylelib/ddlc.mplstyle".source = self.lib.matplotlib.light;
        "matplotlib/stylelib/ddlc-dark.mplstyle".source = self.lib.matplotlib.dark;
        "matplotlib/ddlc_cmaps.py".source = self.lib.matplotlib.cmaps;
      };
    })

    (lib.mkIf cfg.claude-code.enable {
      # ~/.claude sits outside XDG, and the filename is the slug /theme lists, so the app
      # segment is dropped on the way in
      home.file = {
        ".claude/themes/ddlc-light.json".source = self.lib.claude-code.light;
        ".claude/themes/ddlc-dark.json".source = self.lib.claude-code.dark;
      };
    })

    (lib.mkIf cfg.opencode.enable {
      # The filename is the theme name, so ddlc-opencode.json lands as ddlc.json; select it
      # with "theme": "ddlc" in opencode's config or /theme in its TUI
      xdg.configFile."opencode/themes/ddlc.json".source = self.lib.opencode;
    })
  ];
}
