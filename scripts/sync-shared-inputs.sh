#!/usr/bin/env bash
# Sync shared inputs section in all galaxio-template.yaml files from
# _common/inputs-shared.yaml (single source of truth).
#
# Replaces the block from "  GatlingPicatinnyVersion:" up to (not including)
# "files:" in each template descriptor.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shared="${repo_root}/_common/inputs-shared.yaml"
templates=(scala-sbt scala-gradle java-gradle java-maven kotlin-gradle kotlin-maven)

for t in "${templates[@]}"; do
  file="${repo_root}/${t}/galaxio-template.yaml"
  python3 - "${file}" "${shared}" <<'PYEOF'
import sys, pathlib

target = pathlib.Path(sys.argv[1])
shared = pathlib.Path(sys.argv[2]).read_text()

lines = target.read_text().splitlines(keepends=True)

# Find start: first line that is exactly "  GatlingPicatinnyVersion:\n"
start = next(
    i for i, l in enumerate(lines)
    if l.rstrip() == "  GatlingPicatinnyVersion:"
)

# Find end: first line starting with "files:" after start
end = next(
    i for i, l in enumerate(lines)
    if i > start and l.startswith("files:")
)

new_lines = lines[:start] + [shared] + lines[end:]
target.write_text("".join(new_lines))
print(f"  synced {sys.argv[1]}")
PYEOF
done

echo "Done. All templates synced from _common/inputs-shared.yaml"
