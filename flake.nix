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
      # Both applications read a theme out of ~/.config, so the module is the two settings that
      # name it — which is the half a consumer keeps getting wrong. lib below stays for a
      # configuration that would rather place the files itself
      # homeModules is the name the flake schema knows; homeManagerModules is what most
      # consumers still write, so both point at the same module
      homeModules.default = import ./nix/module.nix { inherit self; };
      homeManagerModules.default = self.homeModules.default;

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
      # For a consumer who reaches for pkgs rather than this flake's packages directly
      overlays.default = final: _prev: {
        ddlc-terminal-themes = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      checks = forAllSystems (pkgs: {
        dist-is-current = pkgs.runCommand "dist-is-current" { } ''
          install -m755 ${generator} generate.sh
          DDLC_BASE16_LIGHT=${schemes.light} DDLC_BASE16_DARK=${schemes.dark} \
            bash generate.sh >/dev/null
          diff -r ${dist} dist
          touch $out
        '';

        # Enabling a switch has to be enough: the colours in kitty's config after its own
        # settings, both btop variants deployed and the theme named — and nothing while disabled
        module-wiring =
          let
            wiring = import ./nix/module-test.nix {
              inherit (nixpkgs) lib;
              module = self.homeManagerModules.default;
            };
          in
          pkgs.runCommand "module-wiring"
            {
              nativeBuildInputs = [ pkgs.jq ];
              dump = builtins.toJSON wiring;
              passAsFile = [ "dump" ];
            }
            ''
              want() { jq -e "$1" "$dumpPath" >/dev/null || { echo "module wiring: $2"; exit 1; }; }

              want '.kitty | test("background #222222")' "the dark colours do not reach kitty"
              want '.kittyLight | test("background #FFFFFF")' "the variant does not reach kitty"
              # kitty takes the last word for a key, so the theme has to land after any setting
              # the consumer wrote next to the module
              want '.kittyOrder | test("#123456[\\s\\S]*#222222")' "the colours do not land last"

              want '.btopFiles | index("btop/themes/ddlc-dark.theme")' "the dark theme is not deployed"
              # Both go in whatever the variant is: btop lists its themes directory, so the other
              # one is a keypress away in its own menu
              want '.btopFiles | index("btop/themes/ddlc-light.theme")' "the light theme is not deployed"
              want '.btopTheme == "ddlc-dark"' "btop does not name the theme"
              want '.btopThemeLight == "ddlc-light"' "the variant does not reach btop"

              want '.offKitty == ""' "kitty is themed while disabled"
              want '.offFiles == []' "a theme is deployed while disabled"
              want '.offTheme == null' "btop is themed while disabled"
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
