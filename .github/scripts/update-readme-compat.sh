#!/usr/bin/env bash
# Regenerates the compatibility table in README.md from manifest sources.
#
# Usage:
#   bash .github/scripts/update-readme-compat.sh
#
# Reads:
#   galaxio-pack.yaml                 — pack version + per-template versions
#   scala-sbt/galaxio-template.yaml   — canonical GatlingVersion / GatlingPicatinnyVersion defaults
#
# Replaces the block between:
#   <!-- compat-table-start -->
#   <!-- compat-table-end -->
# in README.md.
#
# No external dependencies — uses only bash, grep, awk, python3 (stdlib only).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readme="${repo_root}/README.md"
pack_yaml="${repo_root}/galaxio-pack.yaml"
ref_template="${repo_root}/scala-sbt/galaxio-template.yaml"

# Verify sentinels exist before proceeding
if ! grep -q '<!-- compat-table-start -->' "${readme}"; then
  echo "ERROR: <!-- compat-table-start --> not found in README.md" >&2
  exit 1
fi

# -- Extract values with grep/awk (no PyYAML required) --
# Pack version: first `version:` line in pack yaml (top-level)
pack_version=$(grep -m1 '^version:' "${pack_yaml}" | awk '{print $2}')

# Template versions: lines after `- name: <template>` blocks
get_template_version() {
  local name="$1"
  # Find the block starting with "- name: <name>" and grab the next "version:" line
  awk "/- name: ${name}/{found=1} found && /version:/{print \$2; exit}" "${pack_yaml}"
}

scala_sbt_ver=$(get_template_version "scala-sbt")
scala_gradle_ver=$(get_template_version "scala-gradle")
java_maven_ver=$(get_template_version "java-maven")
java_gradle_ver=$(get_template_version "java-gradle")
kotlin_maven_ver=$(get_template_version "kotlin-maven")
kotlin_gradle_ver=$(get_template_version "kotlin-gradle")

# Gatling/Picatinny: find `  GatlingVersion:` block, grab `default:` on next non-empty line
get_input_default() {
  local key="$1"
  awk "/^  ${key}:/{found=1} found && /default:/{print \$2; exit}" "${ref_template}"
}

gatling_version=$(get_input_default "GatlingVersion")
picatinny_version=$(get_input_default "GatlingPicatinnyVersion")

echo "Pack: ${pack_version} | Gatling: ${gatling_version} | Picatinny: ${picatinny_version}"

# -- Build new block content --
new_block="<!-- compat-table-start -->
> **Auto-generated** — do not edit this block manually. Run \`bash .github/scripts/update-readme-compat.sh\` to refresh.

### Render-time vs runtime versions

**Pack version** (\`${pack_version}\`) is render-time metadata: \`galaxio-cli\` resolves this
version when you run \`galaxio template init gatling/<template>\` and downloads the matching pack
from the registry.

**Gatling** and **Picatinny** versions are *default runtime dependency values* injected into the
generated project's build file. Override any of them at render time with \`--set Flag=value\`:

\`\`\`bash
galaxio template init gatling/scala-sbt \\\\
  --set GatlingVersion=3.14.0 \\\\
  --set GatlingPicatinnyVersion=1.13.0
\`\`\`

The pack \`apiVersion: galaxio.io/v1\` requires a CLI build that supports the v1 schema.
Consult the \`galaxio-cli\` release notes for the minimum compatible CLI version.

### Version table

Pack version: \`${pack_version}\` · Gatling default: \`${gatling_version}\` · Picatinny default: \`${picatinny_version}\`

| Template | Language | Build tool | Template version | Gatling | Picatinny |
|---|---|---|---|---|---|
| \`scala-sbt\` | Scala | sbt | \`${scala_sbt_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`scala-gradle\` | Scala | Gradle | \`${scala_gradle_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`java-maven\` | Java | Maven | \`${java_maven_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`java-gradle\` | Java | Gradle | \`${java_gradle_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`kotlin-maven\` | Kotlin | Maven | \`${kotlin_maven_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`kotlin-gradle\` | Kotlin | Gradle | \`${kotlin_gradle_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |

All templates share the same Gatling and Picatinny defaults. See
[\`galaxio-pack.yaml\`](galaxio-pack.yaml) for the authoritative template version list.
<!-- compat-table-end -->"

# -- Replace block in README.md (python3 stdlib only) --
python3 - "${readme}" <<PYEOF
import re, sys

readme_path = sys.argv[1]
with open(readme_path) as f:
    content = f.read()

new_block = """${new_block}"""

updated, count = re.subn(
    r'<!-- compat-table-start -->.*?<!-- compat-table-end -->',
    new_block,
    content,
    flags=re.DOTALL,
)
if count == 0:
    sys.exit("ERROR: sentinel comments not found in README.md")

with open(readme_path, "w") as f:
    f.write(updated)
print("README.md updated.")
PYEOF
