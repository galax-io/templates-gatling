#!/usr/bin/env bash
# Regenerates the compatibility table in README.md from manifest sources.
#
# Usage:
#   bash .github/scripts/update-readme-compat.sh
#
# Reads:
#   galaxio-pack.yaml         — pack version, per-template versions
#   */galaxio-template.yaml   — GatlingVersion / GatlingPicatinnyVersion defaults
#                               (all templates must agree; script fails on divergence)
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

# Verify sentinels exist before proceeding
if ! grep -q '<!-- compat-table-start -->' "${readme}"; then
  echo "ERROR: <!-- compat-table-start --> not found in README.md" >&2
  exit 1
fi

# -- Extract pack-level values -----------------------------------------------
pack_version=$(grep -m1 '^version:' "${pack_yaml}" | awk '{print $2}')

# Template versions: find `- name: <template>` block, grab next `version:` line
get_template_version() {
  local name="$1"
  awk "/- name: ${name}/{found=1} found && /version:/{print \$2; exit}" "${pack_yaml}"
}

scala_sbt_ver=$(get_template_version "scala-sbt")
scala_gradle_ver=$(get_template_version "scala-gradle")
java_maven_ver=$(get_template_version "java-maven")
java_gradle_ver=$(get_template_version "java-gradle")
kotlin_maven_ver=$(get_template_version "kotlin-maven")
kotlin_gradle_ver=$(get_template_version "kotlin-gradle")

# -- Read + cross-validate Gatling/Picatinny defaults across all templates ----
get_input_default() {
  local manifest="$1" key="$2"
  awk "/^  ${key}:/{found=1} found && /default:/{print \$2; exit}" "${manifest}"
}

templates="scala-sbt scala-gradle java-maven java-gradle kotlin-maven kotlin-gradle"
ref_gatling=""
ref_picatinny=""
diverged=0

for tmpl in ${templates}; do
  manifest="${repo_root}/${tmpl}/galaxio-template.yaml"
  g=$(get_input_default "${manifest}" "GatlingVersion")
  p=$(get_input_default "${manifest}" "GatlingPicatinnyVersion")

  if [[ -z "${ref_gatling}" ]]; then
    ref_gatling="${g}"
    ref_picatinny="${p}"
  elif [[ "${g}" != "${ref_gatling}" || "${p}" != "${ref_picatinny}" ]]; then
    echo "WARNING: ${tmpl} has diverging defaults: Gatling=${g} (expected ${ref_gatling}), Picatinny=${p} (expected ${ref_picatinny})" >&2
    diverged=1
  fi
done

if [[ "${diverged}" -eq 1 ]]; then
  echo "ERROR: Template defaults are not uniform. Fix the manifests or update the script to render per-template values." >&2
  exit 1
fi

gatling_version="${ref_gatling}"
picatinny_version="${ref_picatinny}"

echo "Pack: ${pack_version} | Gatling: ${gatling_version} | Picatinny: ${picatinny_version}"

# -- Build new block content --------------------------------------------------
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

The pack uses \`apiVersion: galaxio.io/v1\`. Consult the
[galaxio-cli releases](https://github.com/galax-io/galaxio-cli/releases) for the minimum
compatible CLI version.

### Version table

Pack \`${pack_version}\` · Gatling \`${gatling_version}\` · Picatinny \`${picatinny_version}\`

| Template | Language | Build tool | Template version | Gatling | Picatinny |
|---|---|---|---|---|---|
| \`scala-sbt\` | Scala | sbt | \`${scala_sbt_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`scala-gradle\` | Scala | Gradle | \`${scala_gradle_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`java-maven\` | Java | Maven | \`${java_maven_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`java-gradle\` | Java | Gradle | \`${java_gradle_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`kotlin-maven\` | Kotlin | Maven | \`${kotlin_maven_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |
| \`kotlin-gradle\` | Kotlin | Gradle | \`${kotlin_gradle_ver}\` | \`${gatling_version}\` | \`${picatinny_version}\` |

All templates share the same Gatling and Picatinny defaults; the script validates this on every run.
See [\`galaxio-pack.yaml\`](galaxio-pack.yaml) for the authoritative template version list.
<!-- compat-table-end -->"

# -- Replace block in README.md (python3 stdlib only) ------------------------
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
