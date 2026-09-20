# Changelog

All notable changes to this plugin are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version
numbers are the ones in `manifest.json`.

## [1.1.0] — 2026-09-21

### Added

- **A Now playing card**, over MPRIS. Title, artist, album, elapsed and
  remaining, album art, and the transport: previous, play/pause, next. It
  follows whatever player is actually playing — Spotify, a browser tab, mpv —
  and `preferredPlayer` pins it to one by name. Each button is enabled from the
  player's own capability flags, so a source that cannot skip shows the button
  dimmed rather than pretending. Control is a D-Bus call, not a subprocess.
- `omarchy-shell omawidgets nowPlaying`, `playPause`, `nextTrack` and
  `previousTrack`, for media keys and scripts.
- **Columns and tile size in the bar popup**, so compact mode can be arranged
  without editing `shell.json`.
- `albumArt`, `preferredPlayer`, `hideMediaWhenIdle`, `tileSize` and
  `tileRadius` settings.

### Changed

- **Compact mode is now a different layout, not a smaller one.** It was full
  cards with tighter padding, which barely saved anything — the Performance card
  alone carries three unrelated readings. Compact now draws one rounded square
  per reading: the single number it exists for, a label above it and a meter
  along the bottom edge. Tile corners come from `tileRadius` independently of the
  theme's own radius, so a square theme still gets rounded tiles.
- Compact defaults to two columns; a single column of small squares wastes the
  space a full card needs.
- The glyph test now rejects a bare BMP private-use character. Every icon here is
  nf-md, which lives in the supplementary plane and always arrives as a surrogate
  pair — so a lone BMP code unit is the exact signature of a five-digit `\uXXXXX`
  escape truncated to four, which renders as a real but entirely wrong glyph.
  It also rejects unexpected non-ASCII text characters, which is the other half
  of the same mistake.

### Fixed

- **The media card stayed empty while a player sat there with a title.**
  `Mpris.players.values` is a QML list: indexable, with a length, and not a
  JavaScript `Array`. Guarding with `Array.isArray` silently yielded an empty
  list. Player selection also had to start watching every player rather than the
  selected one — selection depends on whether a player has a title yet, so before
  the first one loads there is no selection to watch.
- Four glyphs were the wrong picture: the transport icons now use the same
  codepoints the stock Omarchy media widget does.

## [1.0.1] — 2026-09-21

### Fixed

- **Picking a position applied the previous pick.** The service read its settings
  from the host's `shell.barConfig` snapshot, which the shell re-pushes only when
  the plugin or widget registry changes — not when a setting is written. The bar
  widget now pushes its own injected settings to the service, which the bar host
  keeps current, so the cards move on the click that asked them to.
- **Top-anchored cards sat underneath the bar.** `ExclusionMode.Ignore` sets a
  layer-shell exclusive zone of `-1`, which asks the compositor to disregard
  every other surface's zone. The desktop windows now use `ExclusionMode.Normal`
  with a zero zone: they reserve nothing themselves but stay clear of the bar,
  on whichever edge it sits.
- **An invalid setting overwrote a valid one.** `write()` merged a raw change
  into an already-normalised object and persisted the result, so a value that
  failed validation reached `shell.json` and the next read replaced it with the
  default. The merged result is now normalised before it is written, and
  `setPosition` rejects an unknown position outright rather than falling back.

### Added

- `omarchy-shell omawidgets-bar position <name>` to move the cards from a script
  or a keybind.

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
