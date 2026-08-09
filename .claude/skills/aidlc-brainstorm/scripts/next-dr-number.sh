#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-aidlc-docs/brainstorming}"
mkdir -p "$DIR"

max=0
while IFS= read -r file; do
  name="$(basename "$file")"
  number="${name%%-*}"
  if [[ "$number" =~ ^[0-9]+$ ]] && ((10#$number > max)); then
    max=$((10#$number))
  fi
done < <(find "$DIR" -maxdepth 1 -type f -name '[0-9][0-9][0-9][0-9]-*.md' 2>/dev/null)

printf '%04d\n' "$((max + 1))"
