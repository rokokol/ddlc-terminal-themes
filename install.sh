#!/usr/bin/env bash
# Copy the rendered themes into a config tree, for anyone not installing this with Nix
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}"
DESTDIR="${DESTDIR:-}"
COMPONENT="${COMPONENT:-all}"

usage() {
  cat <<EOF
install.sh — install the DDLC kitty and btop themes

  --component C    install kitty, btop, or all (default: $COMPONENT)
  --kitty          compatibility shorthand for --component kitty
  --btop           compatibility shorthand for --component btop
  --config-home D  install under D instead of $config
  --destdir D      prepend a staging root (default: ${DESTDIR:-<empty>})

kitty gets both variants next to kitty.conf, where an include with a bare name resolves.
btop lists a theme under its filename, so the app segment is dropped on the way in and
ddlc-btop-dark.theme lands as ddlc-dark.theme
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

case "$COMPONENT" in
  all | kitty | btop) ;;
  *)
    echo "install.sh: component must be kitty, btop, or all: $COMPONENT" >&2
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
