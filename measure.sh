#!/usr/bin/env bash
# Usage: ./measure.sh <attr> <label>   (attr: default | crane)
set -euo pipefail
attr=$1; label=$2
git add -A >/dev/null
s=$(date +%s.%N)
nix build ".#$attr" --dry-run 2>&1 | sed -n '/will be built/,/will be fetched/p' | grep '\.drv' | sed 's|.*/[a-z0-9]\{32\}-||' > /tmp/plan.txt || true
e=$(date +%s.%N)
s2=$(date +%s.%N); nix build ".#$attr" --no-link -L >/tmp/build.log 2>&1; e2=$(date +%s.%N)
printf '%s [%s]: eval+plan %.1fs, build %.1fs, %d drv(s) built: %s\n' "$label" "$attr" "$(awk "BEGIN{print $e-$s}")" "$(awk "BEGIN{print $e2-$s2}")" "$(wc -l </tmp/plan.txt)" "$(tr '\n' ' ' </tmp/plan.txt)"
grep -o "Compiling demo-[a-z]*" /tmp/build.log | sort -u | tr "\n" " " | sed "s/^/   cargo compiled: /"; echo
