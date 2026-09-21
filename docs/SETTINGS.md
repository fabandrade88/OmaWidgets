# Settings, arranging and IPC

[← README](../README.md)

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

## Keybindings

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

## IPC

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

omarchy-shell omawidgets addTodo "Ship the plugin"   # no deadline; set one in the card
omarchy-shell omawidgets todos                       # "3 open  1 done  2 archived"
omarchy-shell omawidgets pomodoro                    # "running  focus  18:42"
omarchy-shell omawidgets startPomodoro               # start or pause
omarchy-shell omawidgets skipPhase
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
| `cards` | all six | Any of `system`, `media`, `todo`, `pods`, `battery`, `power`, in the order you want them |
| `focusMinutes` | `25` | 1–180 |
| `shortBreakMinutes` | `5` | 1–60 |
| `longBreakMinutes` | `15` | 1–120 |
| `longBreakEvery` | `4` | 1–12 focus rounds before the long break |
| `todoRows` | `5` | 1–20 rows listed on the card; the rest are summarised as a count |
| `dateFormat` | `dd-MM-yyyy` | Also `dd/MM/yyyy`, `yyyy-MM-dd`, `MM/dd/yyyy` |
| `timeFormat` | `24h` | Or `12h` |
| `columns` | `1`, or `2` in compact | 1–6 on the desktop. Widgets are packed shortest-first, so a short one never leaves a hole under it, and the compact Performance tile spans two columns. The overlay ignores this and fits as many as the screen holds, wrapping the rest onto a second row |
| `cards` order | — | Also the order on the desktop. Dragging a widget rewrites it |
| `cardWidth` | `268` | 180–520 pixels |
| `spacing` | `10` | 0–48 pixels between cards |
| `marginX` / `marginY` | `28` / `20` | Distance from the screen edges |
| `opacity` | `0.92` | 0.2–1. The colour itself comes from the theme |
| `compact` | `false` | Compact tiles instead of full cards |
| `tileSize` | `132` | 88–260 pixels. Tiles are square, so one number sizes them |
| `tileRadius` | `18` | 0–64 pixels. Independent of the theme's radius, so a square theme still gets rounded tiles |
| `hideMediaWhenIdle` | `true` | Drop the media card when nothing is playing |
| `albumArt` | `true` | Show cover art. See [Running someone else's code](SECURITY.md#running-someone-elses-code) |
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
