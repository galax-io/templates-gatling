#!/usr/bin/env bash
# Regenerates the version-bearing README.md tables from manifest sources, so
# they cannot drift from the templates the way hand-maintained tables did.
#
# Usage:
#   bash .github/scripts/update-readme-compat.sh
#
# Reads:
#   galaxio-pack.yaml         — pack version, per-template versions
#   */galaxio-template.yaml   — input defaults. Inputs declared by every template
#                               (Gatling, Picatinny, the three plugin versions,
#                               PostgresDriver, KafkaStreams) must agree across all
#                               six; the script fails on divergence. Inputs specific
#                               to one language or build tool are read from a
#                               template that declares them.
#
# Replaces each block between <!-- <name>-start --> and <!-- <name>-end --> for
# every name in `blocks` below:
#   compat-table     — pack/Gatling/Picatinny version table
#   inputs-common    — inputs shared by all templates
#   inputs-langtool  — language and build-tool inputs
#   inputs-plugins   — optional plugin module versions
#
# No external dependencies — uses only bash, grep, awk, python3 (stdlib only).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readme="${repo_root}/README.md"
pack_yaml="${repo_root}/galaxio-pack.yaml"

# Every block this script owns. Each is delimited by <!-- <name>-start/end --> in README.md.
blocks=(compat-table inputs-common inputs-langtool inputs-plugins)

# Verify sentinels exist before proceeding
for block in "${blocks[@]}"; do
  if ! grep -q "<!-- ${block}-start -->" "${readme}"; then
    echo "ERROR: <!-- ${block}-start --> not found in README.md" >&2
    exit 1
  fi
done

# -- Extract pack-level values -----------------------------------------------
pack_version=$(grep -m1 '^version:' "${pack_yaml}" | awk '{print $2}')

# Template versions: find the `- name: <template>` block and grab its `version:`.
# Block-scoped (stops at the next `- name:`) and exact-field matched, so a missing
# version line yields empty instead of bleeding into the next template's version.
get_template_version() {
  local name="$1"
  awk -v name="$name" '
    $1 == "-" && $2 == "name:" && $3 == name { found = 1; next }
    found && $1 == "-" && $2 == "name:" { exit }
    found && $1 == "version:" { print $2; exit }
  ' "${pack_yaml}"
}

scala_sbt_ver=$(get_template_version "scala-sbt")
scala_gradle_ver=$(get_template_version "scala-gradle")
java_maven_ver=$(get_template_version "java-maven")
java_gradle_ver=$(get_template_version "java-gradle")
kotlin_maven_ver=$(get_template_version "kotlin-maven")
kotlin_gradle_ver=$(get_template_version "kotlin-gradle")

# -- Read input defaults out of the template manifests ------------------------
# Prints everything after `default:` for the given input, minus surrounding
# quotes. Multi-word values ("60 rpm") and quoted ones ("17") both come back
# intact, so the generated tables match the manifests exactly.
get_input_default() {
  local manifest="$1" key="$2"
  awk -v key="  ${key}:" '
    $0 == key { found = 1; next }
    found && /^    default:/ {
      sub(/^[[:space:]]*default:[[:space:]]*/, "")
      sub(/^["'"'"']/, "")
      sub(/["'"'"']$/, "")
      print
      exit
    }
    found && /^  [A-Za-z]/ { exit }   # next input began without a default
  ' "${manifest}"
}

templates="scala-sbt scala-gradle java-maven java-gradle kotlin-maven kotlin-gradle"

# Inputs every template declares and must agree on. Divergence is an error:
# the tables below render one value for all six.
uniform_default() {
  local key="$1" ref="" val="" tmpl=""
  for tmpl in ${templates}; do
    val="$(get_input_default "${repo_root}/${tmpl}/galaxio-template.yaml" "${key}")"
    if [[ -z "${val}" ]]; then
      echo "ERROR: ${tmpl} declares no default for ${key}." >&2
      return 1
    fi
    if [[ -z "${ref}" ]]; then
      ref="${val}"
    elif [[ "${val}" != "${ref}" ]]; then
      echo "ERROR: ${key} diverges across templates: ${tmpl}=${val}, expected ${ref}." >&2
      echo "       Fix the manifests, or teach this script to render per-template values." >&2
      return 1
    fi
  done
  printf '%s' "${ref}"
}

# Inputs only some templates declare — read from one that has it.
template_default() {
  get_input_default "${repo_root}/${1}/galaxio-template.yaml" "$2"
}

gatling_version="$(uniform_default GatlingVersion)"
picatinny_version="$(uniform_default GatlingPicatinnyVersion)"
kafka_plugin_version="$(uniform_default KafkaPluginVersion)"
kafka_streams_version="$(uniform_default KafkaStreamsVersion)"
jdbc_plugin_version="$(uniform_default JdbcPluginVersion)"
amqp_plugin_version="$(uniform_default AmqpPluginVersion)"
postgres_driver_version="$(uniform_default PostgresDriverVersion)"

name_default="$(template_default scala-sbt Name)"
name_word_default="$(template_default scala-sbt NameWord)"
package_default="$(template_default scala-sbt Package)"
package_path_default="$(template_default scala-sbt PackagePath)"
base_url_default="$(template_default scala-sbt BaseUrl)"
intensity_default="$(template_default scala-sbt Intensity)"

scala_version="$(template_default scala-sbt ScalaVersion)"
sbt_version="$(template_default scala-sbt SbtVersion)"
sbt_gatling_version="$(template_default scala-sbt SbtGatlingVersion)"
sbt_scalafmt_version="$(template_default scala-sbt SbtScalafmtVersion)"
java_version="$(template_default java-gradle JavaVersion)"
maven_version="$(template_default java-maven MavenVersion)"
kotlin_version="$(template_default kotlin-maven KotlinVersion)"
gradle_wrapper_version="$(template_default java-gradle GradleWrapperVersion)"
gatling_gradle_plugin_version="$(template_default java-gradle GatlingGradlePluginVersion)"
gatling_maven_plugin_version="$(template_default java-maven GatlingMavenPluginVersion)"

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
galaxio template init gatling/scala-sbt \\
  --set GatlingVersion=3.14.0 \\
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

inputs_common_block="<!-- inputs-common-start -->
> **Auto-generated** — do not edit this block manually. Run \`bash .github/scripts/update-readme-compat.sh\` to refresh.

| Input | Default | Notes |
| --- | --- | --- |
| \`Name\` | \`${name_default}\` | Project name used in the README and build descriptor. |
| \`NameWord\` | \`${name_word_default}\` | Name as a valid identifier — used in package/class names. Must not contain spaces or hyphens. |
| \`Package\` | \`${package_default}\` | Base package for generated sources. |
| \`PackagePath\` | \`${package_path_default}\` | \`Package\` with dots replaced by \`/\`. Must stay in sync — see note below. |
| \`GatlingVersion\` | \`${gatling_version}\` | Gatling version injected into the build file. |
| \`GatlingPicatinnyVersion\` | \`${picatinny_version}\` | Galaxio Gatling Picatinny library version. |
| \`BaseUrl\` | \`${base_url_default}\` | Target base URL written to \`simulation.conf\`. |
| \`Intensity\` | \`${intensity_default}\` | Default load intensity written to \`simulation.conf\`. |
<!-- inputs-common-end -->"

inputs_langtool_block="<!-- inputs-langtool-start -->
> **Auto-generated** — do not edit this block manually. Run \`bash .github/scripts/update-readme-compat.sh\` to refresh.

| Input | Templates | Default |
| --- | --- | --- |
| \`ScalaVersion\` | \`scala-sbt\`, \`scala-gradle\` | \`${scala_version}\` |
| \`JavaVersion\` | \`java-*\`, \`kotlin-*\`, \`scala-gradle\` | \`${java_version}\` |
| \`KotlinVersion\` | \`kotlin-maven\`, \`kotlin-gradle\` | \`${kotlin_version}\` |
| \`SbtVersion\` | \`scala-sbt\` | \`${sbt_version}\` |
| \`MavenVersion\` | \`java-maven\`, \`kotlin-maven\` | \`${maven_version}\` |
| \`GradleWrapperVersion\` | \`*-gradle\` | \`${gradle_wrapper_version}\` |
| \`SbtGatlingVersion\` | \`scala-sbt\` | \`${sbt_gatling_version}\` |
| \`SbtScalafmtVersion\` | \`scala-sbt\` | \`${sbt_scalafmt_version}\` |
| \`GatlingMavenPluginVersion\` | \`java-maven\`, \`kotlin-maven\` | \`${gatling_maven_plugin_version}\` |
| \`GatlingGradlePluginVersion\` | \`*-gradle\` | \`${gatling_gradle_plugin_version}\` |

\`GatlingGradlePluginVersion\` tracks the Gatling version it supports, so it stays on the
\`${gatling_version}.x\` line for as long as \`GatlingVersion\` is \`${gatling_version}\`.
<!-- inputs-langtool-end -->"

inputs_plugins_block="<!-- inputs-plugins-start -->
> **Auto-generated** — do not edit this block manually. Run \`bash .github/scripts/update-readme-compat.sh\` to refresh.

| Plugin | Enable input | Version input | Default |
| --- | --- | --- | --- |
| Kafka | \`KafkaPluginEnabled\` | \`KafkaPluginVersion\` | \`${kafka_plugin_version}\` |
| JDBC | \`JdbcPluginEnabled\` | \`JdbcPluginVersion\` | \`${jdbc_plugin_version}\` |
| AMQP | \`AmqpPluginEnabled\` | \`AmqpPluginVersion\` | \`${amqp_plugin_version}\` |

The JDBC overlay also pulls the PostgreSQL driver, pinned by \`PostgresDriverVersion\`
(\`${postgres_driver_version}\`), and the Kafka overlay pins \`org.apache.kafka:kafka-streams\` with
\`KafkaStreamsVersion\` (\`${kafka_streams_version}\`) — see the note below.
<!-- inputs-plugins-end -->"

# -- Replace the owned blocks in README.md (python3 stdlib only) -------------
# Each block is staged to a file so the replacement text never passes through
# a regex-substitution escape (\\1, \\g<1>) or another round of shell quoting.
block_dir="$(mktemp -d)"
trap 'rm -rf "${block_dir}"' EXIT
printf '%s' "${new_block}" > "${block_dir}/compat-table"
printf '%s' "${inputs_common_block}" > "${block_dir}/inputs-common"
printf '%s' "${inputs_langtool_block}" > "${block_dir}/inputs-langtool"
printf '%s' "${inputs_plugins_block}" > "${block_dir}/inputs-plugins"

python3 - "${readme}" "${block_dir}" "${blocks[@]}" <<'PYEOF'
import pathlib, re, sys

readme_path, block_dir = sys.argv[1], sys.argv[2]
names = sys.argv[3:]

content = pathlib.Path(readme_path).read_text()

for name in names:
    replacement = pathlib.Path(block_dir, name).read_text()
    pattern = r"<!-- %s-start -->.*?<!-- %s-end -->" % (re.escape(name), re.escape(name))
    content, count = re.subn(pattern, lambda _m: replacement, content, flags=re.DOTALL)
    if count == 0:
        sys.exit(f"ERROR: sentinel comments for {name} not found in README.md")
    if count > 1:
        sys.exit(f"ERROR: sentinel comments for {name} appear {count} times in README.md")

pathlib.Path(readme_path).write_text(content)
print("README.md updated.")
PYEOF
