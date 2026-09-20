#!/usr/bin/env bash
#
# Everything that can be checked without a running compositor:
#
#   1. the manifest, against the same schema the shell enforces
#   2. the pure-JS model, under node
#   3. the QML, under qmllint
#   4. the shell scripts, under shellcheck
#   5. the hardware probe, on this machine
#   6. the 200-line-per-file limit this repo holds itself to
#
# The QML step needs an import root containing a `qs` directory, because the
# shell's singletons declare `module qs.Commons`. Quickshell maps its config root
# to `qs` itself; qmllint needs to be told.
set -euo pipefail
cd "$(dirname "$0")/.."

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
QMLLINT="${QMLLINT:-/usr/lib/qt6/bin/qmllint}"
status=0

step() { printf '\n\033[1m%s\033[0m\n' "$1"; }

step "manifest"
if command -v omarchy-plugin-validate >/dev/null 2>&1; then
  omarchy-plugin-validate . && echo "ok   manifest — passes the shell's own validator"
else
  jq -e . manifest.json >/dev/null && echo "ok   manifest — valid JSON (omarchy-plugin-validate not on PATH)"
fi

step "model"
for test in tests/*.test.js; do
  node "$test" || status=1
done

step "qml"
if [[ -x $QMLLINT ]]; then
  root=$(mktemp -d)
  trap 'rm -rf "$root"' EXIT
  ln -sfn "$OMARCHY_PATH/shell" "$root/qs"
  # Only the diagnostics that mean something here. qmllint cannot see into the
  # inline QtObject sub-objects the theme singletons are built from (Style.font,
  # Color.popups), cannot resolve `root` or `modelData` from inside a Component or
  # a Repeater delegate, and does not know Quickshell registers PanelWindow — all
  # of which the first-party Omarchy plugins trip too.
  if "$QMLLINT" -I "$root" -I /usr/lib/qt6/qml ./*.qml 2>&1 |
    grep -E '\[(property-override|unused-imports|deprecated|incompatible-type|duplicate-property-binding|read-only-property|missing-type|non-list-property|var-used-before-declaration|invalid-lint-directive)\]$'; then
    echo "FAIL qml — see above"
    status=1
  else
    echo "ok   qml — no actionable qmllint diagnostics"
  fi
else
  echo "skip qml — $QMLLINT not installed (qt6-declarative-tools)"
fi

step "shell"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck scripts/*; then echo "ok   shell — shellcheck is clean"; else status=1; fi
else
  echo "skip shell — shellcheck not installed"
fi

step "size"
# The limit is a design constraint, not a style preference: a file that outgrows
# it is doing more than one job. Enforced so it cannot drift.
over=0
while IFS= read -r file; do
  lines=$(wc -l <"$file")
  if ((lines > 200)); then
    printf '     %-32s %s lines\n' "$file" "$lines"
    over=$((over + 1))
  fi
done < <(git ls-files '*.qml' '*.js' 'scripts/*' 'tests/*' 2>/dev/null || find . -path ./.git -prune -o -type f \( -name '*.qml' -o -name '*.js' \) -print)
if ((over > 0)); then
  echo "FAIL size — $over file(s) over 200 lines"
  status=1
else
  echo "ok   size — every source file is 200 lines or fewer"
fi

step "probe"
if output=$(./scripts/omawidgets-probe); then
  printf '%s\n' "$output" | sed 's/^/     /'
  echo "ok   probe — exited 0 on this machine"
else
  echo "FAIL probe — non-zero exit"
  status=1
fi
if ./scripts/omawidgets-probe unexpected-argument >/dev/null 2>&1; then
  echo "FAIL probe — accepted an argument"
  status=1
else
  echo "ok   probe — refuses arguments"
fi

printf '\n'
((status == 0)) && echo "all checks passed" || echo "there were failures"
exit "$status"
