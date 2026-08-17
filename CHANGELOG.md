# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by [semver](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Changed

- `install.sh` accepts a staging `DESTDIR` and a `kitty|btop|all` component while retaining the short `--kitty` and `--btop` forms

## [1.0.0] - 2026-08-13

Split out of [rokokol/huix](https://github.com/rokokol/huix), where the kitty and btop generators were two hundred lines inside `ddlc-palette`'s `generate.sh`

### Added

- kitty and btop themes, light and dark, rendered from the base16 schemes in `ddlc-palette`
- `dist/`, committed for consumers without Nix, and `install.sh` that places btop's theme under the name it is found by
- `homeModules.default`, `overlays.default`
- checks: `dist/` is current, every slot is filled, the module wires both applications up and touches neither while disabled
- a weekly `palette-drift.yml` that re-renders against the palette's HEAD rather than the lock
