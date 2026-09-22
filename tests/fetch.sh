#!/usr/bin/env bash
#
# The fetch helper, against a server written to be hostile.
#
# Every network read this plugin performs goes through that script, so its exit
# codes are the whole contract: nothing else decides whether an oversized, slow
# or mistyped response is allowed to become a file.
set -uo pipefail
cd "$(dirname "$0")/.."

command -v python3 >/dev/null 2>&1 || { echo "skip fetch — python3 not installed"; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "skip fetch — curl not installed"; exit 0; }

PORT=${OMAWIDGETS_TEST_PORT:-18731}
RUNTIME=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
OUT_DIR="$RUNTIME/omawidgets/test-fetch"
SCRIPT=./scripts/omawidgets-fetch
status=0
passed=0

cat > /tmp/omawidgets-hostile-$$.py <<PY
import http.server, sys, time
PORT = $PORT
class H(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path == "/flood":                      # chunked, never declared, never ends
            self.send_response(200); self.send_header("Transfer-Encoding", "chunked"); self.end_headers()
            chunk = b"A" * 65536
            try:
                for _ in range(4096): self.wfile.write(b"%x\r\n" % len(chunk) + chunk + b"\r\n"); self.wfile.flush()
            except Exception: pass
        elif self.path == "/declared":                  # 50 MB, declared
            self.send_response(200); self.send_header("Content-Length", str(50 * 1024 * 1024)); self.end_headers()
            try:
                for _ in range(800): self.wfile.write(b"B" * 65536); self.wfile.flush()
            except Exception: pass
        elif self.path == "/stall":                     # headers, then nothing
            self.send_response(200); self.send_header("Content-Length", "100"); self.end_headers(); time.sleep(600)
        elif self.path == "/html-as-png":               # a lie about the type
            body = b"<html>not an image</html>"
            self.send_response(200); self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
        elif self.path == "/png":
            png = bytes.fromhex("89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c6360000002000100ffff03000006000557bfabd40000000049454e44ae426082")
            self.send_response(200); self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(png))); self.end_headers(); self.wfile.write(png)
        elif self.path == "/redirect-to-file":
            self.send_response(302); self.send_header("Location", "file:///etc/passwd")
            self.send_header("Content-Length", "0"); self.end_headers()
        elif self.path.startswith("/many"):
            body = bytes.fromhex("89504e470d0a1a0a") + b"x" * 64
            self.send_response(200); self.send_header("Content-Length", str(len(body)))
            self.end_headers(); self.wfile.write(body)
        elif self.path == "/json":
            body = b'{"version":"9.9.9"}'
            self.send_response(200); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
        else:
            self.send_response(404); self.end_headers()
http.server.ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
PY
python3 /tmp/omawidgets-hostile-$$.py & server=$!
trap 'kill $server 2>/dev/null; rm -f /tmp/omawidgets-hostile-$$.py; rm -rf "$OUT_DIR"' EXIT
for _ in $(seq 40); do curl -s -o /dev/null --max-time 1 "http://127.0.0.1:$PORT/json" && break; sleep 0.1; done

check() {
  local want=$1 what=$2; shift 2
  rm -f "$OUT_DIR/out.img"
  "$@" >/dev/null 2>&1
  local got=$?
  if [[ $got == "$want" ]]; then
    passed=$((passed + 1))
  else
    printf '     %-46s expected %s, got %s\n' "$what" "$want" "$got"
    status=1
  fi
}

base="http://127.0.0.1:$PORT"
check 5 "a chunked flood is cut at the cap"        $SCRIPT "$base/flood" "$OUT_DIR/out.img" 65536
check 5 "a declared 50 MB body is refused"         $SCRIPT "$base/declared" "$OUT_DIR/out.img" 65536
check 5 "headers then silence runs out of time"    $SCRIPT "$base/stall" "$OUT_DIR/out.img" 65536
check 9 "html served as image/png is not an image" $SCRIPT "$base/html-as-png" "$OUT_DIR/out.img" 65536 image
check 0 "a real png is fetched"                    $SCRIPT "$base/png" "$OUT_DIR/out.img" 65536 image
check 0 "and so is a small json body"              $SCRIPT "$base/json" "$OUT_DIR/out.img" 65536
check 9 "a json body is not an image"              $SCRIPT "$base/json" "$OUT_DIR/out.img" 65536 image

check 3 "a file:// url is refused"                 $SCRIPT "file:///etc/passwd" "$OUT_DIR/out.img" 65536
check 3 "a command substitution is refused"        $SCRIPT 'http://x/$(id)' "$OUT_DIR/out.img" 65536
check 3 "a backtick is refused"                    $SCRIPT 'http://x/`id`' "$OUT_DIR/out.img" 65536
check 3 "a cap that is not a number is refused"    $SCRIPT "$base/json" "$OUT_DIR/out.img" 64kb
check 3 "a cap above the hard ceiling is refused"  $SCRIPT "$base/json" "$OUT_DIR/out.img" 99999999
check 4 "a destination outside the runtime dir"    $SCRIPT "$base/json" "/tmp/omawidgets-escape.img" 65536
check 4 "a destination that climbs out of it"      $SCRIPT "$base/json" "$OUT_DIR/../../../escape.img" 65536
check 2 "no arguments at all"                      $SCRIPT
check 5 "a redirect off http(s) is not followed"   $SCRIPT "$base/redirect-to-file" "$OUT_DIR/out.img" 65536

# A player that rewrites its artwork in a loop must not be able to fill a tmpfs.
for i in $(seq 12); do
  $SCRIPT "$base/many?$i" "$OUT_DIR/art-$i.img" 65536 >/dev/null 2>&1
done
kept=$(ls -1 "$OUT_DIR"/art-*.img 2>/dev/null | wc -l)
if (( kept <= 8 )); then
  passed=$((passed + 1))
else
  printf '     %-46s expected at most 8 kept, found %s\n' "twelve fetches prune down to the newest" "$kept"
  status=1
fi

if ((status == 0)); then
  echo "ok   fetch — $passed hostile cases refused or served as specified"
else
  echo "FAIL fetch — see above"
fi
exit $status
