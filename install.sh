#!/usr/bin/env bash
# Copy the rendered themes into a config tree, for anyone not installing this with Nix
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}"
what=""

usage() {
  cat <<EOF
install.sh — install the DDLC kitty and btop themes

  --kitty          only kitty
  --btop           only btop
                   (default: both)
  --config-home D  install under D instead of $config

kitty gets both variants next to kitty.conf, where an include with a bare name resolves.
btop lists a theme under its filename, so the app segment is dropped on the way in and
ddlc-btop-dark.theme lands as ddlc-dark.theme
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kitty | --btop)
      what="${1#--}"
      shift
      ;;
    --config-home)
      config="${2:?directory required}"
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

here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [ -z "$what" ] || [ "$what" = kitty ]; then
  install -d "$config/kitty"
  install -m644 "$here"/dist/ddlc-kitty-*.conf "$config/kitty"
  echo "kitty: installed into $config/kitty — add \"include ddlc-kitty-dark.conf\" to kitty.conf"
fi

if [ -z "$what" ] || [ "$what" = btop ]; then
  install -d "$config/btop/themes"
  for variant in light dark; do
    install -m644 "$here/dist/ddlc-btop-$variant.theme" "$config/btop/themes/ddlc-$variant.theme"
  done
  echo "btop: installed into $config/btop/themes — set color_theme = \"ddlc-dark\" in btop.conf"
fi
