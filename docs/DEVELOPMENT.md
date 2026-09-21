# Hacking on it

[← README](../README.md)


```bash
git clone https://github.com/fabandrade88/OmaWidgets.git
cd OmaWidgets
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

## How it is put together

Everything that parses or decides lives in `model/` as plain JavaScript with no
QML imports, so `node` runs the same source the shell does. Everything in QML is
either a service that reads files or a component that draws, and each folder is
one of those jobs.

```
manifest.json     three kinds: a service, a bar widget, an overlay
Service.qml       the one long-lived instance: owns every sampler and the desktop surface
BarWidget.qml     the bar icon, the settings popup, and the only write path to shell.json
Overlay.qml       the summoned surface

services/         everything that reads the machine
  SystemService     CPU and memory, on a gated timer
  GpuService        GPU, from sysfs or nvidia-smi
  PodsService       AirPods, from a file watch — no timer
  PowerService      UPower, and the power profile
  MediaService      MPRIS: player selection and transport
  TodoService       the to-do file, the Pomodoro countdown, and the alarm
  HardwareProbe     runs scripts/omawidgets-probe once per session
  GuardedFile       a watched file with a size it refuses to keep re-reading
  ServiceIpc        the `omawidgets` IPC target

surfaces/         where the cards are put, and how they are arranged
  DesktopSurface    layer-shell windows on WlrLayer.Bottom, one per screen
  OverlaySurface    the dimmed full-screen surface
  CardStack         picks full cards or compact tiles
  PackedLayout      places, selects and drags; CardColumn and TileGrid are its delegates
  Arranger          the selection, and what hiding or dragging asks for

cards/            the full cards, and the parts only they use
  Card, SystemCard, MediaCard, PodsCard, BatteryCard, PowerCard, TodoCard
  CoreBars, HistoryGraph, MetricRow, PomodoroDial, TodoRow, TodoComposer

tiles/            compact mode
  Tile, SystemTile, MediaTile, PodsTile, TodoTile

settings/         the contents of the bar popup
  SettingsPanel, CardsSection, LayoutSettings, TodoSettings,
  ExpanderSection, ChoiceRow, StepperRow, ToggleRow, PositionGrid

ui/               drawing shared by more than one of the above
  IconRing, RingGauge, MetricGauge, MeterBar, CloseButton,
  ProfileSelector, MediaControls, PodGauge, PodMark, TodoColors (singleton)

model/            pure JavaScript, no QML imports — `node` runs it
  Sysfs             /proc and hwmon parsers
  Gpu               one shape from three driver families
  Pods              the librepods status file, defensively
  Power             battery presentation, and the profile allowlist
  Media             MPRIS player selection and track presentation
  Todo, TodoList    the to-do file format, list operations, deadline urgency
  Pomodoro          the focus and break cycle
  DateTime          reading and writing deadlines in the chosen format
  Layout, Pack      which widgets are worth drawing, and column packing
  Arrange           selecting, hiding and reordering
  Settings          normalisation and clamping
  Format, Series    numbers and units; bounded sample history
  Probe             the probe's output, and the path allowlist

scripts/omawidgets-probe      one-shot sensor discovery, no arguments, read-only
scripts/omawidgets-probe-gpu  the GPU half of it, sourced rather than run
scripts/omawidgets-dev-install
```

A component in another folder is reached with a directory import —
`import "../ui"` — so every file says at the top which layers it depends on.

Every source file is 200 lines or fewer, and `./tests/run.sh` fails if one
stops being: a file that outgrows the limit is doing more than one job.

## Tests

```bash
./tests/run.sh
```

- **`model.test.js`** — formatting, `/proc` parsing, GPU normalisation across all
  three driver families, bounded history.
- **`input.test.js`** — the paths where being wrong has consequences: the power
  profile allowlist, truncated and hostile librepods JSON, hand-edited settings.
- **`layout.test.js`** — card and tile arrangement, window anchoring, and column
  packing including two-column items.
- **`arrange.test.js`** — selecting, hiding and reordering, and which player the
  media card should follow, including the QML-list case that is indexable but is
  not a JavaScript `Array`.
- **`todo.test.js`** — the to-do file in both directions, deadline urgency, and
  the Pomodoro cycle.
- **`datetime.test.js`** — parsing and formatting deadlines in every supported
  format, including dates that do not exist and the placeholders themselves.
- **`security.test.js`** — what may reach a command, an argument vector or a
  path.
- **`hostile.test.js`** — what a media player registered by any application, a
  separate daemon, or a hand-edited file may put in front of you.
- **`glyphs.test.js`** — every Nerd Font glyph in the source, against the font
  the bar actually uses. It catches both a codepoint the font lacks and a
  malformed surrogate pair, which is not one character at all and looks like a
  styling problem rather than the typo it is.

`run.sh` also validates the manifest against the shell's own validator, lints
the QML, runs `shellcheck` over the scripts when it is installed, runs the
hardware probe on the machine you are sitting at, and enforces the line limit.
