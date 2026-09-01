# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by [semver](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Added

- matplotlib styles and colormaps — `ddlc.mplstyle`, `ddlc-dark.mplstyle` and `ddlc_cmaps.py`, moved over from [rokokol/huix](https://github.com/rokokol/huix) so the theme ships with the family instead of living in one rice; the light cycler's order is its colour-blind safety mechanism and the dark one is three colours because the palette is polarised. `docs/matplotlib-demo.py` renders the demo figures the README shows
- Claude Code themes, `ddlc-claude-code-{dark,light}.json` for `~/.claude/themes/` — the dark leans into the slots ddlc.nvim draws from base16 dark, blush text and neon pink frames, the light sits on the colours that actually read on paper, and every foreground slot is contrast-checked against its own ground
- `ddlc-report.css` — the matplotlib theme spoken in CSS for HTML reports: one file, light by default, dark under `prefers-color-scheme` with `data-theme` winning, the series as `--ddlc-series-*` custom properties; `docs/report-demo.html` renders the README screenshots
- an opencode theme, `ddlc-opencode.json` — one file for both variants, its `defs` carrying the palette by name so the mapping stays readable in place
- `generate.sh` takes the flat `palette.env` as a third input, because these three themes have more roles than sixteen base16 slots
- module switches `matplotlib.enable`, `claude-code.enable` and `opencode.enable`, deploy-only and variant-less — each application picks its own variant, and none of the switches touches the application's config
- `install.sh` components `matplotlib`, `claude-code` and `opencode`, with `--claude-home` for the one application that reads outside `~/.config`

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
