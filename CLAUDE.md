# CLAUDE.md

## What this repo is

The DDLC colours as a kitty theme and a btop theme, light and dark, rendered by `generate.sh` out of the base16 schemes in `ddlc-palette`. Nothing here is a taste call except which slot goes where. `dist/` holds the rendered configs, committed for consumers without Nix

Two seams in `rokokol/huix`, and no module on either: `programs/term/kitty.nix` does `readFile lib.kitty.dark`, `programs/cli/btop.nix` sets `source = lib.btop.dark`. That is deliberate — the themes are files, and a module would only wrap two `readFile`s

## Build / check

```sh
nix build                # the rendered themes
nix flake check          # dist/ current, every slot filled, module wiring, shell lint
./install.sh --config-home "$PWD/out"
nix fmt -- --ci
```

There is no `tests/`: the repo renders data, and `dist-is-current` is the suite

## Layout

```
generate.sh   the mapping: base16 slots in, two configs per variant out
nix/          module.nix, module-test.nix
dist/         the rendered themes, committed for consumers without Nix
install.sh    for systems without Nix
```

## Changing a colour

It comes from `ddlc-palette` as a base16 scheme, never a literal here. What this repo may change is which slot goes where, in `generate.sh` — then regenerate `dist/`, or `dist-is-current` fails. The weekly `palette-drift.yml` re-renders against the palette's HEAD rather than the lock and opens a pull request when a colour has moved upstream

btop only finds a theme under the name it lands with, which is why `install.sh` places the files by name rather than copying a directory

## CHANGELOG

Every user-visible change adds a bullet under `## [Unreleased]` in `CHANGELOG.md`. A release moves those bullets under a new version heading with the date, tags `v<x.y.z>` and cuts a `gh release` whose notes are that section. Dates belong in this file and nowhere else — the no-dates rule holds everywhere but here, because Keep a Changelog asks for them
