{
  description = "The Doki Doki Literature Club themes for kitty and btop, light and dark";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ddlc-palette = {
      url = "github:rokokol/ddlc-palette";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ddlc-palette,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Each piece isolated, so a README edit doesn't rebuild anything
      generator = builtins.path {
        name = "generate.sh";
        path = ./generate.sh;
      };
      installer = builtins.path {
        name = "install.sh";
        path = ./install.sh;
      };
      dist = builtins.path {
        name = "ddlc-terminal-themes-dist";
        path = ./dist;
      };

      schemes = ddlc-palette.lib.dist.base16;
    in
    {
      # The rendered themes as paths, so a consumer names an app and a variant instead of a
      # filename. There is deliberately no module behind them: readFile or a source = is the
      # whole integration
      #   kitty.extraConfig = builtins.readFile ddlc-terminal-themes.lib.kitty.dark;
      lib = {
        kitty = {
          light = ./dist/ddlc-kitty-light.conf;
          dark = ./dist/ddlc-kitty-dark.conf;
        };
        btop = {
          light = ./dist/ddlc-btop-light.theme;
          dark = ./dist/ddlc-btop-dark.theme;
        };
      };

      packages = forAllSystems (pkgs: {
        default =
          pkgs.runCommand "ddlc-terminal-themes"
            {
              meta = {
                description = "The Doki Doki Literature Club themes for kitty and btop";
                homepage = "https://github.com/rokokol/ddlc-terminal-themes";
                # MIT covers the generator; the colours themselves are Team Salvato's
                license = pkgs.lib.licenses.mit;
                # Plain config files — nothing here is built for a platform
                platforms = pkgs.lib.platforms.all;
              };
            }
            ''
              mkdir -p $out/share/ddlc-terminal-themes
              cp -r ${dist}/. $out/share/ddlc-terminal-themes/
            '';
      });

      # dist/ is committed so a consumer without Nix just copies files; this proves it is what
      # the generator would write today against the palette this flake is locked to
      checks = forAllSystems (pkgs: {
        dist-is-current = pkgs.runCommand "dist-is-current" { } ''
          install -m755 ${generator} generate.sh
          DDLC_BASE16_LIGHT=${schemes.light} DDLC_BASE16_DARK=${schemes.dark} \
            bash generate.sh >/dev/null
          diff -r ${dist} dist
          touch $out
        '';

        # The generator is the repository as much as dist/ is, so its lint is a check like any
        # other — CI then runs nothing that a local nix flake check does not
        shell-is-clean =
          pkgs.runCommand "shell-is-clean"
            {
              nativeBuildInputs = [
                pkgs.shellcheck
                pkgs.shfmt
              ];
            }
            ''
              shellcheck ${generator} ${installer}
              shfmt -i 2 -ci -d ${generator} ${installer}
              touch $out
            '';

        # A theme is only usable if every colour reached it, and a missing slot renders as an
        # empty value rather than as an error
        themes-are-filled = pkgs.runCommand "themes-are-filled" { } ''
          for f in ${dist}/ddlc-kitty-*.conf; do
            grep -Eq '^color21 #[0-9A-F]{6}$' "$f" || { echo "$f: the ANSI table is short"; exit 1; }
            if grep -Ev '^(#|$)' "$f" | grep -Ev ' #[0-9A-F]{6}$'; then
              echo "$f: the value above is not a hex colour" >&2
              exit 1
            fi
          done
          for f in ${dist}/ddlc-btop-*.theme; do
            grep -q 'theme\[main_bg\]="#' "$f" || { echo "$f: no background"; exit 1; }
            # Only the mid and end of a scaleless meter are deliberately empty
            if grep -Ev '^(#|$)' "$f" | grep -Ev '^theme\[[a-z_]+\]="(#[0-9A-F]{6})?"$'; then
              echo "$f: the line above is not a theme[key]=\"#hex\"" >&2
              exit 1
            fi
          done
          touch $out
        '';
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.shellcheck
            pkgs.shfmt
          ];
          # So generate.sh runs with no arguments inside the shell
          DDLC_BASE16_LIGHT = schemes.light;
          DDLC_BASE16_DARK = schemes.dark;
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
