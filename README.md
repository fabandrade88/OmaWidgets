<h1 align="center">OmaWidgets</h1>

<p align="center">
  Desktop widget cards for Omarchy, in the spirit of the macOS desktop.<br>
  CPU, memory and GPU. Now playing. AirPods battery. Battery. Power profile, one click.<br>
  Or the same readings as small rounded tiles.
</p>

<p align="center">
  <img src="preview.png" alt="Four OmaWidgets cards on the Omarchy desktop" width="360">
</p>

<p align="center">
  <em>Every colour, border, corner radius and type size comes from your active Omarchy theme.<br>
  Switch themes and the cards switch with the rest of the shell, in the same frame.</em>
</p>

## Two ways to read them

**On the desktop.** The cards sit on a Wayland `bottom` layer: above the wallpaper,
below every application window. They are there when you look at the desktop and
out of the way when you are working. The window is sized to the cards and
anchored to one corner, so the rest of your wallpaper keeps its own
double-click-to-change-background behaviour.

**As an overlay.** The same cards, side by side on a dimmed full-screen surface,
summoned by a keybind and dismissed with `Escape`. One layout, one set of
readings, two ways to look at them.

<p align="center">
  <img src="docs/overlay.png" alt="The summoned overlay" width="760">
</p>

## Compact mode

Compact is a different layout, not a smaller one. Each widget becomes a rounded
square: a ring with its mark inside and the reading underneath, the way iOS and
macOS draw a battery widget.

Performance keeps its three readings together in one wide tile — CPU, memory and
GPU are the three halves of "what is this machine doing", and reading them as
three squares scattered through a grid is worse than reading them side by side.
The AirPods tile packs its rings into a two-by-two. The media tile puts the cover
where the others put their ring, with the track underneath and progress along the
bottom of the art.

<p align="center">
  <img src="docs/tiles.png" alt="Compact tiles" width="300">
</p>

Tile corners are rounded from `tileRadius`, independently of the theme's own
corner radius: a theme with square corners still wants its small tiles rounded,
and that softness is the whole visual idea. Everything else — colour, border,
type — still comes from the theme.

The columns and tile size are in the bar popup, and compact defaults to two
columns because a single column of small squares wastes the space a full card
needs. The summoned overlay always shows the full cards: it has the whole
screen, so there is nothing to compact.

## The cards

### Performance

A gauge for CPU load with the package temperature under it, a strip of recent
history, and one bar per thread. Then memory, swap when any is in use, and the
GPU.

The GPU row is where hardware honesty matters. The three driver families expose
completely different things:

| | utilisation | temperature | clock | VRAM |
|---|---|---|---|---|
| **amdgpu** | `gpu_busy_percent` | own hwmon sensor | hwmon | `mem_info_vram_*` |
| **nvidia** | `nvidia-smi` | `nvidia-smi` | `nvidia-smi` | `nvidia-smi` |
| **i915 / xe** | *none available* | shares the CPU package sensor | `gt_act_freq` | shared with system RAM |

Intel exposes no busy counter in sysfs. `intel_gpu_top` can produce one, but
only with `CAP_PERFMON` or a relaxed `perf_event_paranoid` — a privilege no
shell plugin should ask you to grant. So an Intel card shows the clock it is
actually running at, marks a shared temperature sensor as `soc`, and says in
one line why there is no percentage. It does not invent one.

### Now playing

Title, artist, album, elapsed and remaining, and the transport: previous,
play/pause, next. It follows whatever MPRIS player is actually playing —
Spotify, a browser tab, mpv, anything that speaks the protocol — and
`preferredPlayer` pins it to one by name when you would rather it did not
wander.

Each button is enabled from the player's own capability flags, so a source that
cannot skip — a live stream, most podcasts — shows the button dimmed and inert
rather than pretending. Album art fills the tile in compact mode and sits beside
the track on the full card.

Control is native: Quickshell speaks MPRIS directly, so skipping a track costs
one D-Bus call, not a subprocess.

### AirPods

A ring per part with its mark inside and the level underneath — the left pod, the
right pod and the case — so the pair and the case are read side by side rather
than as three stacked bars. Charging breaks the ring at twelve o'clock. In compact
mode the same rings pack into a two-by-two square.

The marks are drawn here rather than taken from a font or from a vendor's
artwork. No Nerd Font glyph is an AirPod, and the nearest candidates say "audio"
without saying *which* bud — the one thing these marks exist to say. The
[omarchy-pods](https://github.com/thisisgm/omarchy-pods) plugin solves it with
Apple's own product outlines lifted from apple.com, which is a reasonable choice
for a plugin but not one worth copying into a separately published one. These are
original silhouettes: one path each, so the head, the ear tip and the stem union
cleanly instead of showing seams where overlapping rectangles meet, and the pair
is genuinely mirrored rather than one picture used twice. An AirPods Max has a
single battery and no case, so it gets one gauge and a headphone mark.

Per-pod and case battery, charging and in-ear hints, the listening mode and the
case lid, all read from the status file the
[librepods](https://github.com/kavishdevar/librepods) daemon publishes at
`$XDG_STATE_HOME/librepods/status.json` — the same file the
[AirPods plugin](https://github.com/thisisgm/omarchy-pods) reads.

**This card displays and does not command.** Listening mode, ear detection,
Conversation Awareness and the rest belong to `io.github.thisisgm.omapods`,
which owns the write path to the daemon. Two panels racing each other's
optimistic writes for one device would be worse than one panel that reports.

The card hides itself when nothing is reporting, so a machine with no AirPods
does not carry a permanent empty card. There is no polling: the daemon rewrites
the file on change and the plugin watches it.

### Battery

Level, what the battery is doing, and how long that leaves — the answer to "how
long have I got" as the headline, with the charge or draw rate, cell health and
cycle count underneath. Everything comes from UPower, which is signal-driven,
so this card costs nothing while it sits there.

### Power profile

Saver, Balanced and Performance as one segmented control. Only the profiles the
running `power-profiles-daemon` actually reported get a segment; a machine
without it shows a line saying so rather than three buttons that would do
nothing.

The compact tile has one gesture, so tapping it cycles and wraps round: Saver,
Balanced, Performance, Saver again. The popup's arrow keys step and stop at the
ends instead, the way arrow keys on a slider do.

Switching goes through Omarchy's own `omarchy-powerprofiles-set`, so your choice
is remembered per power source exactly as the stock power panel remembers it —
set Performance on AC and Saver on battery, and Omarchy restores each one when
you plug and unplug.

## Install

```bash
omarchy plugin add https://github.com/fabandrade88/omawidgets.git
omarchy plugin enable io.github.fabandrade88.omawidgets --section right
```

Plugins land disabled so you can read the code before you run it. That is worth
doing — see [Running someone else's code](#running-someone-elses-code).

To remove it completely:

```bash
omarchy plugin remove io.github.fabandrade88.omawidgets
```

## Using it

A bar icon appears on the right of your bar. It is dimmed while the desktop
cards are hidden.

| | |
|---|---|
| **Left click** | Open the settings popup |
| **Right click** | Show or hide the desktop cards |
| **Middle click** | Summon the overlay |
| **← →** in the popup | Step through the power profiles |
| **Escape** | Close the popup or the overlay |

<p align="center">
  <img src="docs/settings-popup.png" alt="The settings popup" width="280">
</p>

The popup holds everything: the desktop toggle, compact mode, per-core bars, a
3×3 picker for where the cards sit, which cards to show, and the power profile.
Changes are written to `~/.config/omarchy/shell.json` as you make them.

## Arranging the desktop

**Hover a widget** and a small X appears in its corner. Clicking it hides the
widget — and because hiding is the same thing as switching it off, the bar
popup's toggle for it goes off at the same time. Turn it back on there.

**Click a widget** to select it; it takes an accent border, and clicking it again
lets go. **Drag it** anywhere in the stack to reorder: the others reflow around
it as you go, and the new order is written to `shell.json` when you drop.

Selecting first also means a click does not fire the widget underneath it: the
first tap on the media tile selects, the second plays or pauses. The transport
buttons, the profile segments and the X all work on the first click either way.

Everything here is scriptable, so the desktop can also be arranged from the
keyboard.

### Keybindings

Add to `~/.config/hypr/bindings.lua`:

Optional — hiding and arranging work with the mouse alone, so these are for
anyone who would rather not reach for it:

```lua
o.bind("SUPER + ALT + TAB",       "Next widget",     "omarchy-shell omawidgets selectNext")
o.bind("SUPER + ALT + W",         "Hide widget",     "omarchy-shell omawidgets hideSelected")
o.bind("SUPER + ALT + RIGHT",     "Move widget on",  "omarchy-shell omawidgets moveSelectedForward")
o.bind("SUPER + ALT + LEFT",      "Move widget back","omarchy-shell omawidgets moveSelectedBack")
o.bind("SUPER + ALT + O",         "Widgets overlay", "omarchy-shell omawidgets toggle")
o.bind("SUPER + SHIFT + ALT + W", "Toggle widgets",  "omarchy-shell omawidgets-bar toggleDesktop")
```

> **`SUPER + W` is Omarchy's Close window**, bound in
> `default/hypr/bindings/tiling.lua`, so this plugin does not take it. If you
> want it anyway, unbind it first — and give closing windows another key.

### IPC

```bash
omarchy-shell omawidgets toggle              # summon or dismiss the overlay
omarchy-shell omawidgets refresh             # re-probe hardware and re-read everything
omarchy-shell omawidgets profile             # print the active power profile
omarchy-shell omawidgets setProfile balanced # set it (rejects anything else)
omarchy-shell omawidgets cycleProfile        # next profile, wrapping
omarchy-shell omawidgets-bar toggleDesktop   # show or hide the desktop cards
omarchy-shell omawidgets-bar position top-left   # move the cards; prints where they ended up

omarchy-shell omawidgets nowPlaying          # "playing<TAB>title<TAB>artist"
omarchy-shell omawidgets playPause           # transport, for media keys or a keybind
omarchy-shell omawidgets nextTrack
omarchy-shell omawidgets previousTrack

omarchy-shell omawidgets selected             # which widget is selected, if any
omarchy-shell omawidgets select pods          # select one by name
omarchy-shell omawidgets selectNext           # walk the selection; selectPrevious too
omarchy-shell omawidgets deselect
omarchy-shell omawidgets hideSelected         # prints what it hid, or "nothing selected"
omarchy-shell omawidgets moveSelectedForward  # reorder from the keyboard
omarchy-shell omawidgets moveSelectedBack
```

`position` takes any of the eight names in the table below. An unknown one
leaves the cards where they are and prints the position they are still in.

## Settings

Everything lives inline on the plugin's entry in `~/.config/omarchy/shell.json`.
The popup writes the same fields, so hand-editing and clicking are the same
thing. Every value is clamped and unknown values fall back to the default, so a
typo costs you one setting rather than the widget.

| Key | Default | |
|---|---|---|
| `desktop` | `true` | Draw the cards on the desktop |
| `position` | `top-right` | `top-left`, `top-center`, `top-right`, `middle-left`, `middle-right`, `bottom-left`, `bottom-center`, `bottom-right`. Margins are measured from the usable area, so the cards clear the bar whichever edge it is on |
| `cards` | all five | Any of `system`, `media`, `pods`, `battery`, `power`, in the order you want them |
| `columns` | `1`, or `2` in compact | 1–6 on the desktop. Widgets are packed shortest-first, so a short one never leaves a hole under it, and the compact Performance tile spans two columns. The overlay always spreads them across one row |
| `cards` order | — | Also the order on the desktop. Dragging a widget rewrites it |
| `cardWidth` | `268` | 180–520 pixels |
| `spacing` | `10` | 0–48 pixels between cards |
| `marginX` / `marginY` | `28` / `20` | Distance from the screen edges |
| `opacity` | `0.92` | 0.2–1. The colour itself comes from the theme |
| `compact` | `false` | Compact tiles instead of full cards |
| `tileSize` | `132` | 88–260 pixels. Tiles are square, so one number sizes them |
| `tileRadius` | `18` | 0–64 pixels. Independent of the theme's radius, so a square theme still gets rounded tiles |
| `hideMediaWhenIdle` | `true` | Drop the media card when nothing is playing |
| `albumArt` | `true` | Show cover art. See [Running someone else's code](#running-someone-elses-code) |
| `preferredPlayer` | `""` | Pin the media card to one player by name, e.g. `spotify`. Empty follows whatever is playing |
| `showCoreBars` | `true` | One bar per CPU thread |
| `intervalMs` | `2000` | 500–60000. Sampling stops entirely while nothing is on screen |
| `monitor` | `""` | A connector name such as `eDP-1`. Empty means every monitor |
| `hidePodsWhenAbsent` | `true` | Drop the AirPods card when no device is reporting |

```json
{
  "id": "io.github.fabandrade88.omawidgets",
  "position": "bottom-right",
  "columns": 2,
  "cards": ["system", "battery"],
  "intervalMs": 1000
}
```

## What it costs

The sampling loop **spawns no processes**. Quickshell's `FileView` reads
`/proc/stat`, `/proc/meminfo`, `/proc/loadavg` and the sysfs nodes directly, and
each file reports its contents back asynchronously as it loads — so nothing
blocks the UI thread and no reading is ever taken from a stale cache.

Three things follow from that:

- **Nothing visible, nothing running.** Every timer is gated on a surface
  actually showing a card. Turn the desktop cards off and the plugin does
  nothing at all until you summon it.
- **One instance, one set of timers.** The bar widget, the desktop cards and the
  overlay all read from a single service, however many of them are open.
- **Event-driven where possible.** AirPods state arrives by inotify, battery by
  UPower signals, and the power profile is re-read only on an AC transition or
  our own write. None of it is polled.

The exceptions are stated plainly: one `bash` invocation at startup to discover
where this machine keeps its sensors, one `busctl` call (about 6ms) when the
power profile could have changed, and — on NVIDIA only, and only while a card is
on screen — `nvidia-smi`, because NVIDIA publishes nothing in sysfs.

## Running someone else's code

Omarchy plugins run unsandboxed inside your long-lived shell process, with your
permissions. That is true of this one too, so here is exactly what it does.

**It reads.** `/proc/stat`, `/proc/meminfo`, `/proc/loadavg`, hwmon and thermal
sensors, the GPU's sysfs nodes, the battery's cycle count, the librepods status
file, and MPRIS metadata over the session bus. All of it read-only.

**It writes two things, both of them yours.** Playback, when you press a
transport button — a `Next`, `Previous` or `PlayPause` call to the player you are
already listening to, and only when that player reports it supports it. And the
power profile, and only through Omarchy's own
`omarchy-powerprofiles-set`. The profile name passes two gates before it reaches
an argument vector: it must be one of the three names `power-profiles-daemon`
defines, and it must appear in the list the running daemon reported for your
machine. Anything else yields an empty string and no command is built.
[`tests/input.test.js`](tests/input.test.js) asserts this against command
substitutions, shell separators, newlines, flags and case variants.

**It asks for no privileges.** No sudo, no polkit, no capabilities, no
`perf_event` access, no setuid helper. If a reading needs a privilege, the
plugin does without the reading.

**It talks to the network in exactly one place, and you can turn it off.**
Album art from a streaming player is a URL on that service's CDN, and showing it
means fetching it — Spotify's art lives at `i.scdn.co`. Set `albumArt` to `false`
and no art is loaded from anywhere; local players' `file://` art is unaffected by
that request either way. The URL's scheme is checked before it reaches an image,
so `https`, `http` and `file` are accepted and a `data:` blob or a `javascript:`
string is dropped. Nothing else in the codebase opens a connection: there is no
HTTP client, no telemetry, and no update check.

For what it is worth, Omarchy's own media widget binds art URLs the same way, so
leaving this on adds no exposure your shell did not already have.

**It treats every input as hostile.** Everything it reads is text written by
another process — a kernel that renamed a field, a daemon caught mid-write, a
`shell.json` edited by hand, an AirPods name chosen on someone's phone. Each one
goes through a typed parser that clamps ranges, strips control characters, caps
lengths, and falls back rather than throwing. Device names are rendered as
`Text.PlainText` and never interpreted.

**Its one helper script takes no arguments.** `scripts/omawidgets-probe` runs
once per session to find where your sensors live. It accepts no input, pins
`PATH`, resolves every path it reports and refuses any that does not land inside
`/sys` or `/proc`. The plugin checks that again before opening one.

## Hacking on it

```bash
git clone https://github.com/fabandrade88/omawidgets.git
cd omawidgets
./tests/run.sh              # manifest, model, QML, and the probe on this machine
./scripts/omawidgets-dev-install
omarchy plugin enable io.github.fabandrade88.omawidgets --section right
```

Saving a file under `~/.config/omarchy/plugins/` hot-reloads it. Run
`./scripts/omawidgets-dev-install` again to push your changes there, or
`omarchy-shell shell rescanPlugins` to force a reload.

```bash
qs log -p "${OMARCHY_PATH:-/usr/share/omarchy}/shell" --tail 40
```

### How it is put together

Everything that parses or decides lives in `model/` as plain JavaScript with no
QML imports, so `node` runs the same source the shell does. Everything in QML is
either a service that reads files or a component that draws.

```
manifest.json        three kinds: a service, a bar widget, an overlay
Service.qml          the one long-lived instance: owns every sampler and the desktop surface
BarWidget.qml        the bar icon, the settings popup, and the only write path to shell.json
Overlay.qml          the summoned surface

SystemService.qml    CPU and memory, on a gated timer
GpuService.qml       GPU, from sysfs or nvidia-smi
PodsService.qml      AirPods, from an inotify watch — no timer
PowerService.qml     UPower, and the power profile
MediaService.qml     MPRIS: player selection and transport
HardwareProbe.qml    runs scripts/omawidgets-probe once per session

DesktopSurface.qml   layer-shell windows on WlrLayer.Bottom, one per screen
OverlaySurface.qml   the dimmed full-screen surface
CardStack.qml        picks the layout
PackedLayout.qml     places, selects and drags; CardColumn.qml and TileGrid.qml
                     are the two sets of delegates it hosts
Arranger.qml         the selection, and what hiding or dragging asks for

SystemCard.qml  MediaCard.qml  PodsCard.qml  BatteryCard.qml  PowerCard.qml
Card.qml  Tile.qml  SystemTile.qml  MediaTile.qml  PodsTile.qml  CloseButton.qml
IconRing.qml  MetricGauge.qml  PodGauge.qml  PodMark.qml  MediaControls.qml
MetricRow.qml  MeterBar.qml  RingGauge.qml  HistoryGraph.qml  CoreBars.qml
PodPill.qml  ProfileSelector.qml  ToggleRow.qml  StepperRow.qml  PositionGrid.qml

model/Sysfs.js       /proc and hwmon parsers
model/Media.js       MPRIS player selection and track presentation
model/Layout.js      which widgets are worth drawing, and how wide each tile is
model/Pack.js        column packing, including two-column items
model/Arrange.js     selecting, hiding and reordering
model/Gpu.js         one shape from three driver families
model/Pods.js        the librepods status file, defensively
model/Power.js       battery presentation, and the profile allowlist
model/Settings.js    normalisation and clamping
model/Format.js      numbers and units
model/Series.js      bounded sample history
model/Probe.js       the probe's output, and the path allowlist

scripts/omawidgets-probe      one-shot sensor discovery, no arguments, read-only
scripts/omawidgets-probe-gpu  the GPU half of it, sourced rather than run
scripts/omawidgets-dev-install
```

Every source file is 200 lines or fewer, and `./tests/run.sh` fails if one
stops being: a file that outgrows the limit is doing more than one job.

### Tests

```bash
./tests/run.sh
```

- **`model.test.js`** — formatting, `/proc` parsing, GPU normalisation across all
  three driver families, bounded history.
- **`input.test.js`** — the paths where being wrong has consequences: the power
  profile allowlist, truncated and hostile librepods JSON, hand-edited settings.
- **`layout.test.js`** — card and tile arrangement, window anchoring, and which
  player the media card should follow, including the QML-list case that is
  indexable but is not a JavaScript `Array`.
- **`glyphs.test.js`** — every Nerd Font glyph in the source, against the font
  the bar actually uses. It catches both a codepoint the font lacks and a
  malformed surrogate pair, which is not one character at all and looks like a
  styling problem rather than the typo it is.

`run.sh` also validates the manifest against the shell's own validator, lints
the QML, runs `shellcheck` over the scripts when it is installed, runs the
hardware probe on the machine you are sitting at, and enforces the line limit.

## Credits

Built on [Quickshell](https://quickshell.org/) and the
[Omarchy](https://omarchy.org) shell's plugin API, whose `Color`, `Style` and
`Border` singletons do all the theming here. AirPods readings come from the
[librepods](https://github.com/kavishdevar/librepods) daemon by way of
[omarchy-pods](https://github.com/thisisgm/omarchy-pods).

## License

MIT. See [LICENSE](LICENSE).
