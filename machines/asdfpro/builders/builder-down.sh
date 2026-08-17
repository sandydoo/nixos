# Exit 0 when a remote builder must be treated as unreachable.
#
# A failed probe is cached for `ttl` seconds.
# Later Nix build sessions then skip the builder at once instead of each
# waiting for the TCP connect timeout (about 75 s on macOS).
#
# Usage: nix-builder-down <host>

host=$1
ttl=600
dir=${TMPDIR:-/tmp}/nix-builder-down
marker=$dir/$host

now=$(date +%s)

if [ -r "$marker" ]; then
  last=$(cat "$marker" 2>/dev/null || echo 0)
  if [ $((now - last)) -lt "$ttl" ]; then
    exit 0
  fi
fi

if nc -z -w 2 "$host" 22 >/dev/null 2>&1; then
  rm -f "$marker"
  exit 1
fi

mkdir -p "$dir" 2>/dev/null || exit 0
echo "$now" > "$marker" 2>/dev/null || true
exit 0
