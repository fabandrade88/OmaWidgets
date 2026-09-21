# Changelog

All notable changes to this plugin are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version
numbers are the ones in `manifest.json`.

## [1.6.0] — 2026-09-21

### Added

- **Date and clock formats are settings.** Dates default to **DD-MM-YYYY** and
  the clock to **24-hour**; `dd/MM/yyyy`, `yyyy-MM-dd` and `MM/dd/yyyy` are the
  alternatives, and both are pickable in the popup. The setting drives the
  placeholders, the parsing and every deadline shown on a card.

  Parsing is done by the plugin rather than handed to Qt's locale parser, so what
  a deadline field accepts follows the setting rather than whatever locale the
  session happens to have — and it can be tested without one. Separators are
  interchangeable, so `30/09/2026` is accepted whichever one the format asked
  for, and `6pm`, `18:00`, `1830` and `18.30` all read as six in the evening. A
  date that does not exist, like the 31st of September, is refused rather than
  rolled forward into October the way `Date()` would.

### Fixed

- **The composer stayed open after adding a to-do from the desktop card.** It
  now closes, the **+** comes back, and the keyboard returns to the window you
  were using. Where the composer is permanent — the overlay and the bar popup —
  it stays put and keeps the cursor, so a list can be typed in one go.

## [1.5.1] — 2026-09-21

### Fixed

- **Switching cards on and off did nothing.** Splitting the popup into sections
  cut at the wrong boundary, so the card list ended up inside the Layout section
  and emitted a signal nothing was connected to. It rendered, and it did not
  work. It is now a folding section of switches, wired to the same ordering rule
  as before.
- **There was no way to add a to-do from the card you were looking at.** The
  composer only appeared where a keyboard was already available — the overlay
  and the bar popup — which is not where anyone looks for it. The desktop card
  now has a **+** button that opens the composer and asks the compositor for the
  keyboard, and gives it back when the composer closes. The layer still refuses
  the keyboard the rest of the time, which is what keeps a desktop widget from
  stealing keys from the window you are working in.
- **The compact to-do tile had a pause glyph floating in a corner.** The clock
  and its running state now sit inside the ring, the way the card's dial reads.
  A tile whose mark is a picture rather than a number was also drawing nothing
  at all: the content was hidden unless there was a glyph or a value, and this
  one has neither.

### Changed

- **The popup's long sections fold.** Cards, Layout, and To-do and Pomodoro each
  collapse to a title and a summary of what they are set to, with a chevron that
  turns. Six widgets of switches plus five Pomodoro steppers was most of the
  popup's height.

## [1.5.0] — 2026-09-21

### Added

- **A to-do card with a Pomodoro clock.** The two share a card because they are
  one activity: you run a focus round *at* something. Focus is 25 minutes, the
  short break 5 and the long break 15, with a long break every fourth round, and
  all four are settings. A finished phase starts the next one and sounds an
  alarm — a chime from the freedesktop sound theme plus a desktop notification;
  a phase you skip into waits for you.

  Each to-do can carry a deadline, and its colour says how close that is: blue
  beyond a day, orange within a day, red within two hours or past it, green when
  done. These are the only fixed colours in the plugin — urgency is information,
  and information that changed meaning with the wallpaper would be a trap — and
  the words beside the stripe say the same thing, so colour is never the only
  signal. To-dos can be archived one at a time or all at once, and brought back.

  The list lives in `$XDG_STATE_HOME/omawidgets/todos.json`, the plugin's own
  directory, and is parsed as defensively as everything else the plugin reads.
  Adding needs a keyboard, which the desktop layer deliberately never takes, so
  it happens in the bar popup or the overlay and the desktop card is where
  things get ticked off.
- `addTodo`, `todos`, `pomodoro`, `startPomodoro` and `skipPhase` over IPC.

### Changed

- **The card list in the bar popup is a dropdown.** Six widgets of switches was
  most of the popup's height, and the list only grows. Turning one on keeps the
  order a drag established rather than resetting it.
- The Pomodoro durations and the number of to-do rows are in the popup, shown
  only when the card that uses them is switched on. The popup's layout controls
  moved into their own section along the way.

### Reverted

- **The AirPods marks are back to the previous drawing.** The single-path
  version was meant to union the housing and the stem without a seam, and side
  by side it was a wash at card size and worse at thirty pixels, where its
  thinner stem started to disappear. Reverted rather than kept for the sake of
  having changed it.

## [1.4.0] — 2026-09-21

### Added

- **An X on a hovered widget hides it.** Hiding lives on the widget itself rather
  than behind a keybind: nothing to discover, nothing to configure, and no chance
  of colliding with a binding Omarchy already uses. Hiding and switching the
  widget off in the bar popup are the same thing, so the popup's toggle follows.
- `omarchy-shell omawidgets cycleProfile`.

### Fixed

- **The compact power tile could not get back to Saver.** Tapping it clamped at
  the end of the list instead of wrapping, so Performance was a dead end. Tapping
  now cycles round; the popup's arrow keys still step and stop at the ends, the
  way arrow keys on a slider do.
- The battery and power tiles were missing the close button their neighbours had.

### Changed

- **The AirPods marks are drawn as proper silhouettes** — a head, an ear tip and
  a stem clearly narrower than the head, in one path each so the shapes union
  without seams. The previous marks were overlapping rounded rectangles that read
  as a blob. They also scale correctly now: the mark was being scaled about the
  middle of a box sized in screen pixels while its coordinates ran 0–100, which
  pushed it outside its own bounds and clipped it to a fragment at any size but
  one.

  The [omarchy-pods](https://github.com/thisisgm/omarchy-pods) plugin draws its
  marks from Apple's own product outlines taken from apple.com. That is a
  reasonable choice for that plugin, but not one worth copying into a separately
  published one, so these are original.

## [1.3.0] — 2026-09-21

### Added

- **Arranging the desktop.** Click a widget to select it, drag it to reorder, and
  hide it with a keybind. The others reflow around a dragged widget as it moves,
  and the new order is written to `shell.json` on drop. All of it is scriptable —
  `select`, `selectNext`, `moveSelectedForward`, `hideSelected` and the rest — so
  the desktop can be arranged from the keyboard as well as with a pointer.
  Selecting first also means a click no longer fires the widget underneath it: the
  first tap on the media tile selects, the second plays or pauses.
- A hidden widget comes back from the bar popup's card toggles.

### Changed

- **CPU, memory and GPU share one wide compact tile** instead of taking three
  squares. They are the three halves of "what is this machine doing", and reading
  them side by side beats hunting for them in a grid. The packer gained support
  for items that span more than one column to make room for it.
- **Compact tiles are one per widget rather than one per reading**, which is also
  what lets a single drag reorder both layouts.
- **Album art in compact is a small square** where the other tiles put their ring,
  with the track underneath and progress along the bottom of the cover. Art filled
  the whole tile before, which put the title on top of whatever the cover happened
  to be and stopped the tile matching the row it was in. The cover is masked to
  its corner radius, because `clip` follows the bounding box and not the radius.
- Packing, selecting, hiding and reordering are now shared by both layouts through
  one `PackedLayout`, rather than each layout arranging itself.

### Note

`SUPER + W` is Omarchy's **Close window**, bound in
`default/hypr/bindings/tiling.lua`. This plugin does not take it; the README
suggests `SUPER + ALT + W` for hiding a widget and shows how to rebind if you
want `SUPER + W` anyway.

## [1.2.0] — 2026-09-21

### Changed

- **The AirPods card is now a ring per part**, with its mark inside and the level
  underneath, the way Apple's own battery widget reads: left pod, right pod, case,
  side by side instead of three stacked bars. Charging breaks the ring at twelve
  o'clock. An AirPods Max gets one gauge and a headphone mark, since it has a
  single battery and no case.
- **The pod marks are drawn rather than set in a font.** No Nerd Font glyph is an
  AirPod, and the nearest candidates say "audio" without saying which bud — which
  is the one thing the card has to say. A few rounded rectangles mirror cleanly,
  so left and right are genuinely mirrored.
- **Compact tiles follow the same design**: a ring with the reading's mark inside
  and the value underneath, and the AirPods tile packs three rings plus an empty
  fourth into a two-by-two square. The previous compact tiles were a label, a
  number and a bar with a large empty space between them.
- **The full-size cards use the same full-circle ring** as the tiles, so a reading
  looks like itself in either layout. `RingGauge` is now `IconRing` with a label
  in the middle rather than a second implementation of an arc.
- CPU, RAM and GPU tiles have distinct marks; three of them were previously the
  same glyph or the wrong picture entirely.

### Fixed

- **Cards left a hole when laid out in more than one column.** A `Grid`'s rows are
  as tall as their tallest cell, so a short card beside the tall Performance card
  left a gap under it and the next card in that column started level with the tall
  one's bottom. Cards are now placed rather than tabulated: each goes to whichever
  column is currently shortest, which closes the gap and keeps the columns near the
  same length.
- Switching between the card layout and the tile layout left a queued
  `Qt.callLater` reaching for a relayout on a destroyed item. The coalescing now
  uses a timer, which belongs to the item and stops with it.
- The glyph test now also rejects an *escaped* BMP private-use value. It already
  caught a bare one, but `"\uF02CB"` is the same mistake written the other way
  round — four hex digits cannot express a supplementary-plane icon, so it is an
  escape for U+F02C followed by the letter B.

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
