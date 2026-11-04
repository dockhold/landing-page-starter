#!/usr/bin/env bash
# Builds the image from this repository (the repository root is the context,
# the root Dockerfile is used, .dockerignore is honoured) and runs it the way
# Dockhold runs apps: uid 1001, every capability dropped, no privilege
# escalation, a 256 MB memory limit with no swap, PORT set.
#
# Two restrictions go further than Dockhold does, to prove the page needs
# nothing else: no network at all (the site downloads nothing while it runs),
# and a read-only root filesystem with only /tmp writable (it writes nothing).
# With no network the requests come from inside the container, over loopback,
# using the image's own wget.
#
#   tests/smoke.sh            build, then test
#   KEEP=1 tests/smoke.sh     leave the temp folder and container behind
#
# Needs docker and bc.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG="${IMG:-landing-page-starter:test}"
WORK="$(mktemp -d)"
NAME="lps-smoke-$$"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf 'ok   %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1"; }

cleanup() {
  if [ -z "${KEEP:-}" ]; then
    docker rm -f "$NAME" >/dev/null 2>&1
    rm -rf "$WORK"
  fi
}
trap cleanup EXIT

start=$(date +%s)
docker build -q -t "$IMG" "$ROOT" >/dev/null || { echo "build failed"; exit 1; }
echo "build: $(( $(date +%s) - start )) s"

docker run -d --name "$NAME" --user 1001:1001 --cap-drop ALL \
  --security-opt no-new-privileges --memory 256m --memory-swap 256m \
  --network none --read-only --tmpfs /tmp -e PORT=8080 "$IMG" >/dev/null

# fetch PATH: headers in $WORK/h, body in $WORK/b, status in $status.
fetch() {
  docker exec "$NAME" sh -c "wget -S -q -O /tmp/b 'http://127.0.0.1:8080$1' 2>/tmp/h; cat /tmp/h" \
    > "$WORK/h" 2>/dev/null
  docker exec "$NAME" sh -c 'cat /tmp/b 2>/dev/null; rm -f /tmp/b' > "$WORK/b" 2>/dev/null
  status="$(grep -o 'HTTP/[0-9.]* [0-9]*' "$WORK/h" | tail -1 | awk '{print $2}')"
}
hv() { # header name -> value of the last response
  tr -d '\r' < "$WORK/h" | awk -v k="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" '
    { sub(/^ +/, ""); i = index($0, ":");
      if (i > 0 && tolower(substr($0, 1, i - 1)) == k) {
        v = substr($0, i + 1); sub(/^ +/, "", v); val = v } }
    END { print val }'
}

up=""
for _ in $(seq 1 60); do
  fetch / ; [ "$status" = 200 ] && { up=1; break; }
  sleep 0.5
done
[ -n "$up" ] || { echo "app did not come up"; docker logs "$NAME"; exit 1; }

echo "== The page"
fetch /
[ "$status" = 200 ] && ok "/ is 200" || bad "/ is $status"
ct="$(hv Content-Type)"
[ "$ct" = "text/html; charset=utf-8" ] && ok "/ Content-Type: $ct" || bad "/ Content-Type is '$ct'"

has() { # description, fixed string expected in the page
  grep -qF -- "$2" "$WORK/b" && ok "$1" || bad "$1 (no '$2')"
}
count() { # description, fixed string, expected number of lines holding it
  local n; n="$(grep -cF -- "$2" "$WORK/b")"
  [ "$n" = "$3" ] && ok "$1: $n" || bad "$1: $n, want $3"
}
has "viewport meta" '<meta name="viewport" content="width=device-width, initial-scale=1" />'
has "Open Graph title" 'property="og:title"'
has "Open Graph description" 'property="og:description"'
has "Twitter card" '<meta name="twitter:card" content="summary" />'
has "Twitter title" 'name="twitter:title"'
has "Twitter description" 'name="twitter:description"'
has "top bar wordmark" '<a class="wordmark" href="#main">Your product</a>'
has "top bar link to how it works" '<a href="#how">How it works</a>'
has "top bar link to the FAQ" '<a href="#faq">FAQ</a>'
has "hero heading" '<h1>'
has "hero call to action" '<a class="button" href="#signup">'
has "hero secondary link" '<a class="button button-ghost" href="#how">How it works</a>'
count "benefit cards" '<li class="card">' 3
count "benefit icons" '<svg class="icon"' 3
has "how it works section" '<section id="how"'
has "numbered steps" '<ol class="grid steps">'
has "screenshot placeholder" '<svg class="shot-art"'
has "FAQ section" '<section id="faq"'
count "FAQ items" '<details>' 4
has "sign-up section" '<section id="signup"'
has "form endpoint comment" 'paste your form endpoint here'
has "email field" 'type="email"'
has "mailto button" 'href="mailto:'
has "Privacy link" '>Privacy</a>'
has "Imprint link" '>Imprint</a>'
grep -qi '<script' "$WORK/b" && bad "the page has a script" || ok "no script in the page"

fetch /style.css
[ "$status" = 200 ] && ok "/style.css is 200" || bad "/style.css is $status"
ct="$(hv Content-Type)"
case "$ct" in text/css*) ok "/style.css Content-Type: $ct" ;; *) bad "/style.css Content-Type is '$ct'" ;; esac
grep -q 'prefers-color-scheme: dark' "$WORK/b" && ok "dark colours in style.css" || bad "no dark colours"

echo "== Files that must not be served"
for p in /README.md /AGENTS.md /Dockerfile /.dockerignore /.gitignore /tests/smoke.sh \
         /docs/verification/ /.github/workflows/check.yml /.git/config; do
  fetch "$p"
  [ "$status" = 404 ] && ok "$p is 404" || bad "$p is $status, want 404"
done

echo "== Runs as uid 1001 with every capability dropped"
uid="$(docker exec "$NAME" id -u)"
[ "$uid" = 1001 ] && ok "uid $uid" || bad "uid $uid"
caps="$(docker exec "$NAME" sh -c 'grep CapEff /proc/1/status' | awk '{print $2}')"
[ "$caps" = 0000000000000000 ] && ok "CapEff $caps" || bad "CapEff $caps"
docker exec "$NAME" sh -c 'touch /site/x' 2>/dev/null && bad "root filesystem is writable" \
  || ok "root filesystem is read-only"

echo "== Memory"
docker stats --no-stream --format 'memory: {{.MemUsage}}' "$NAME"

echo "== SIGTERM"
start=$(date +%s.%N)
docker stop -t 15 "$NAME" >/dev/null
end=$(date +%s.%N)
code="$(docker inspect -f '{{.State.ExitCode}}' "$NAME")"
secs="$(echo "$end - $start" | bc)"
if [ "$(echo "$secs < 10" | bc)" = 1 ]; then ok "stopped in ${secs}s (exit $code)"; else bad "stop took ${secs}s (exit $code)"; fi

echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
