# Changelog

All notable changes to this plugin are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version
numbers are the ones in `manifest.json`.

## [1.0.0] — 2026-09-21

First release.

### Added

- **Performance card** — CPU load gauge with package temperature, a recent
  history strip, one bar per thread, memory, swap, and a GPU row that adapts to
  amdgpu, nvidia and i915/xe rather than assuming one of them.
- **AirPods card** — per-pod and case battery, charging and in-ear hints,
  listening mode and case lid, read from the librepods daemon's status file.
  Display only; the controls stay with `io.github.thisisgm.omapods`.
- **Battery card** — level, state, time remaining, charge and draw rate, cell
  health and cycle count, from UPower.
- **Power profile card** — Saver, Balanced and Performance as a segmented
  control, offering only the profiles the running daemon reported, and switching
  through `omarchy-powerprofiles-set` so the choice is remembered per power
  source.
- **Desktop surface** — layer-shell windows on `WlrLayer.Bottom`, one per
  screen, sized to their content and anchored to any of eight screen positions.
- **Overlay surface** — the same cards on a dimmed full-screen surface, summoned
  over IPC and dismissed with `Escape`.
- **Bar widget** — an icon plus a popup holding every setting, and the only
  write path to `shell.json`.
- **Zero-spawn sampling** — `/proc` and sysfs are read with Quickshell's
  `FileView`, timers stop whenever nothing is on screen, and AirPods, battery
  and the power profile are event-driven rather than polled.
