#!/usr/bin/env bash
# Copy the rendered themes into a config tree, for anyone not installing this with Nix
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
DESTDIR="${DESTDIR:-}"
COMPONENT="${COMPONENT:-all}"

usage() {
  cat <<EOF
install.sh — install the DDLC kitty, btop, matplotlib, Claude Code and opencode themes

  --component C    install kitty, btop, matplotlib, claude-code, opencode, or all
                   (default: $COMPONENT)
  --kitty          compatibility shorthand for --component kitty
  --btop           compatibility shorthand for --component btop
  --config-home D  install under D instead of $config
  --claude-home D  install the Claude Code themes under D instead of $claude_home
  --destdir D      prepend a staging root (default: ${DESTDIR:-<empty>})

kitty gets both variants next to kitty.conf, where an include with a bare name resolves.
btop, Claude Code and opencode list a theme under its filename, so the app segment is
dropped on the way in: ddlc-btop-dark.theme lands as ddlc-dark.theme, the Claude Code
themes as ddlc-dark.json and ddlc-light.json, and ddlc-opencode.json as ddlc.json.
matplotlib keeps its names — they are the API: plt.style.use("ddlc"), import ddlc_cmaps.
Everything lands as a plain file, yours to edit; only Claude Code reads outside
~/.config, which is what --claude-home covers
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kitty | --btop)
      COMPONENT="${1#--}"
      shift
      ;;
    --component)
      COMPONENT="${2:?component required}"
      shift 2
      ;;
    --config-home)
      config="${2:?directory required}"
      shift 2
      ;;
    --claude-home)
      claude_home="${2:?directory required}"
      shift 2
      ;;
    --destdir)
      DESTDIR="${2:?directory required}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -n "$DESTDIR" && "$config" != /* ]]; then
  echo "install.sh: config home must be absolute when DESTDIR is set: $config" >&2
  exit 1
fi
if [[ -n "$DESTDIR" && "$claude_home" != /* ]]; then
  echo "install.sh: claude home must be absolute when DESTDIR is set: $claude_home" >&2
  exit 1
fi

case "$COMPONENT" in
  all | kitty | btop | matplotlib | claude-code | opencode) ;;
  *)
    echo "install.sh: component must be kitty, btop, matplotlib, claude-code, opencode, or all: $COMPONENT" >&2
    exit 1
    ;;
esac

here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
root="${DESTDIR%/}$config"

if [[ "$COMPONENT" == all || "$COMPONENT" == kitty ]]; then
  install -d "$root/kitty"
  install -m644 "$here"/dist/ddlc-kitty-*.conf "$root/kitty"
  echo "kitty: installed into $root/kitty — add \"include ddlc-kitty-dark.conf\" to kitty.conf"
fi

if [[ "$COMPONENT" == all || "$COMPONENT" == btop ]]; then
  install -d "$root/btop/themes"
  for variant in light dark; do
    install -m644 "$here/dist/ddlc-btop-$variant.theme" "$root/btop/themes/ddlc-$variant.theme"
  done
  echo "btop: installed into $root/btop/themes — set color_theme = \"ddlc-dark\" in btop.conf"
fi

if [[ "$COMPONENT" == all || "$COMPONENT" == matplotlib ]]; then
  install -d "$root/matplotlib/stylelib"
  install -m644 "$here/dist/ddlc.mplstyle" "$here/dist/ddlc-dark.mplstyle" "$root/matplotlib/stylelib"
  install -m644 "$here/dist/ddlc_cmaps.py" "$root/matplotlib"
  echo "matplotlib: installed into $root/matplotlib — plt.style.use(\"ddlc\"), import ddlc_cmaps"
fi

if [[ "$COMPONENT" == all || "$COMPONENT" == claude-code ]]; then
  claude_themes="${DESTDIR%/}$claude_home/themes"
  install -d "$claude_themes"
  for variant in light dark; do
    install -m644 "$here/dist/ddlc-claude-code-$variant.json" "$claude_themes/ddlc-$variant.json"
  done
  echo "claude-code: installed into $claude_themes — pick ddlc-dark or ddlc-light in /theme"
fi

if [[ "$COMPONENT" == all || "$COMPONENT" == opencode ]]; then
  install -d "$root/opencode/themes"
  install -m644 "$here/dist/ddlc-opencode.json" "$root/opencode/themes/ddlc.json"
  echo "opencode: installed into $root/opencode/themes — set \"theme\": \"ddlc\" or pick it in /theme"
fi
