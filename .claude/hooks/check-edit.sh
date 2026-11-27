#!/bin/bash
# PostToolUse hook: after Claude edits a file, run the fastest relevant check and
# feed real errors back so they get fixed in the same turn (less manual checking).
#   .dart -> dart analyze (errors only)      .php -> php -l (syntax)
f=$(python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); print((d.get("tool_input") or {}).get("file_path",""))
except Exception:
    print("")')
[ -z "$f" ] && exit 0
[ -f "$f" ] || exit 0

case "$f" in
  *.g.dart|*.freezed.dart) exit 0 ;;
  *.dart)
    case "$f" in
      */RIDERSIDE/lib/*|*/FRONTEND/lib/*|*/RIDERSIDE/test/*|*/FRONTEND/test/*) ;;
      *) exit 0 ;;
    esac
    pkg="${f%%/lib/*}"; [ "$pkg" = "$f" ] && pkg="${f%%/test/*}"
    out=$(cd "$pkg" && dart analyze "$f" 2>&1 | grep -E "^\s+error" | head -8)
    if [ -n "$out" ]; then
      echo "dart analyze found errors in $f:" >&2
      echo "$out" >&2
      exit 2
    fi
    ;;
  *.php)
    out=$(php -l "$f" 2>&1)
    if [ $? -ne 0 ]; then
      echo "PHP syntax error in $f:" >&2
      echo "$out" >&2
      exit 2
    fi
    ;;
esac
exit 0
