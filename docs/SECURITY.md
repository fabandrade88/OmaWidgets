# What it costs, and what it can reach

[← README](../README.md)

## What it costs

Measured on this machine, as a percentage of one core, taking the lowest of five
samples because a busy desktop makes any single reading meaningless:

| | |
|---|---|
| Plugin enabled, cards hidden | **+0.0** points over the shell alone |
| Six cards on the desktop, 2s interval | **+4.5** points |
| Six cards, 500ms interval | +30 points |

The first row is the design working: with nothing on screen every timer is
stopped, and the plugin is indistinguishable from not having it installed. The
third is why the interval has a floor — the cost is per update, so a quarter of
the interval is four times the work.

Getting the middle row from 7.5 to 4.5 was one change: the progress rings no
longer animate their sweep. Easing an arc re-tessellates it on every frame, and
with six rings on screen that was 2.6 points — more than a third of the plugin's
entire cost — to soften a change that happens every two seconds and reads
perfectly well as a step. Switching the rings to Qt's cheaper geometry renderer
would have saved another 0.6, and was rejected: it is visibly jagged at these
sizes.


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

**It writes three things, all of them yours.** Its own to-do list, at
`$XDG_STATE_HOME/omawidgets/todos.json` — the plugin's own directory, created on
first run, never `shell.json`, which belongs to the bar. Playback, when you press
a transport button — a `Next`, `Previous` or `PlayPause` call to the player you are
already listening to, and only when that player reports it supports it. And the
power profile, and only through Omarchy's own
`omarchy-powerprofiles-set`. The profile name passes two gates before it reaches
an argument vector: it must be one of the three names `power-profiles-daemon`
defines, and it must appear in the list the running daemon reported for your
machine. Anything else yields an empty string and no command is built.
[`tests/input.test.js`](../tests/input.test.js) asserts this against command
substitutions, shell separators, newlines, flags and case variants.

**It asks for no privileges.** No sudo, no polkit, no capabilities, no
`perf_event` access, no setuid helper. If a reading needs a privilege, the
plugin does without the reading.

**It talks to the network in two places, and you can turn both off.**

The first is the update check: one `GET` of this repository's published
`manifest.json`, at most once a day, to compare the published version with the
installed one. It sends nothing — no identifier, no settings, no usage — and
the URL is rebuilt from an allowlisted `https://github.com/<owner>/<repo>`
shape rather than followed as written, so a hand-edited manifest cannot aim it
elsewhere. The response is bounded before it is parsed and the version has to
look like a version. `updateCheck: false` stops it entirely; the popup's
**Check now** button still works, because asking outright is a different thing
from asking on a timer.

**It does not update itself.** The popup's **Update** button opens a terminal
running Omarchy's own `omarchy plugin update <id>`, which shows a diff of what
would change and asks before touching the checkout. That review step is the one
guarantee the installer makes, and a plugin that quietly replaced its own code
would be taking it away. The id is re-validated against the same shape
`omarchy-plugin-validate` enforces before it reaches a command line.

The second is album art. Art from a streaming player is a URL on that service's
CDN, and showing it means fetching it — Spotify's art lives at `i.scdn.co`. Set
`albumArt` to `false` and no art is loaded from anywhere; local players'
`file://` art is unaffected by that request either way. The URL's scheme is
checked before it reaches an image, so `https`, `http` and `file` are accepted
and a `data:` blob or a `javascript:` string is dropped.

Nothing else in the codebase opens a connection: no telemetry, no analytics, and
nothing that reports anything about you anywhere.

For what it is worth, Omarchy's own media widget binds art URLs the same way, so
leaving this on adds no exposure your shell did not already have.

**It has been attacked on purpose.** `tests/security.test.js` and
`tests/hostile.test.js` push command substitutions, shell separators, option-
looking strings, path traversal, oversized values, prototype-pollution keys and
bidirectional overrides through every input the plugin reads — 330 assertions
across the profile allowlist, the probe's paths, MPRIS metadata, the librepods
file, the to-do file and `shell.json`. The same payloads were then written to the
real files on a running shell: nothing executed, nothing crashed, and `<b>bold</b>`
rendered as the six characters it is.

Two findings came out of it. Bidirectional override characters
(U+202A–202E, U+2066–2069) were being rendered: a to-do reading `GNIHTEMOS`
displayed as `SOMETHING`, which is the Trojan Source trick. They are stripped
now, everywhere foreign text is accepted. And a file large enough to matter is
refused before it is turned into a string — Quickshell's `FileView` has no way to
bound a read, so an oversized file is detected by its byte length and then not
re-read on every change, which stops a daemon rewriting a huge file from
compounding the cost.

**It treats every input as hostile.** Everything it reads is text written by
another process — a kernel that renamed a field, a daemon caught mid-write, a
`shell.json` edited by hand, an AirPods name chosen on someone's phone, its own
to-do file after someone edited it. Each one
goes through a typed parser that clamps ranges, strips control characters, caps
lengths, and falls back rather than throwing. Device names are rendered as
`Text.PlainText` and never interpreted.

**Its one helper script takes no arguments.** `scripts/omawidgets-probe` runs
once per session to find where your sensors live. It accepts no input, pins
`PATH`, resolves every path it reports and refuses any that does not land inside
`/sys` or `/proc`. The plugin checks that again before opening one.
