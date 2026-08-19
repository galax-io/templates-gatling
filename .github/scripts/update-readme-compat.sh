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
#                               six; the script fails on divergence. Inputs specific to
#                               one language or build tool are cross-checked across every
#                               template that declares them, so a row can never state a
#                               value only one of them uses.
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
# Each manifest is parsed exactly ONCE by awk into a "<key>\t<default>" blob held
# in a shell variable; every lookup below is pure bash and spawns no process.
# Keys are matched on fields, not whole lines, so trailing whitespace or a
# trailing comment on an input key does not make the input read as missing.
# Multi-word values ("60 rpm") and quoted ones ("17") come back intact.
templates=(scala-sbt scala-gradle java-maven java-gradle kotlin-maven kotlin-gradle)

for tmpl in "${templates[@]}"; do
  printf -v "cache_${tmpl//-/_}" '%s' "$(
    awk '
      # A two-space-indented "Key:" starts a new input.
      /^  [A-Za-z]/ && $1 ~ /:$/ { key = substr($1, 1, length($1) - 1); next }
      key != "" && $1 == "default:" {
        value = $0
        sub(/^[[:space:]]*default:[[:space:]]*/, "", value)
        sub(/[[:space:]]+$/, "", value)
        sub(/^["'"'"']/, "", value)
        sub(/["'"'"']$/, "", value)
        print key "\t" value
        key = ""
      }
    ' "${repo_root}/${tmpl}/galaxio-template.yaml"
  )"
done

get_input_default() {
  local cache_var="cache_${1//-/_}" wanted="$2" key value
  while IFS=$'\t' read -r key value; do
    if [[ "${key}" == "${wanted}" ]]; then
      printf '%s' "${value}"
      return 0
    fi
  done <<< "${!cache_var}"
}

# Reads one input across every template that declares it and requires them to
# agree. Reports ALL diverging templates before failing, so one run shows every
# manifest that needs fixing. Used for single-template inputs too, where it
# degenerates to a presence check.
agreed_default() {
  local key="$1"; shift
  local ref="" val="" tmpl="" diverged=""
  for tmpl in "$@"; do
    val="$(get_input_default "${tmpl}" "${key}")"
    if [[ -z "${val}" ]]; then
      echo "ERROR: ${tmpl} declares no default for ${key}." >&2
      return 1
    fi
    if [[ -z "${ref}" ]]; then
      ref="${val}"
    elif [[ "${val}" != "${ref}" ]]; then
      diverged="${diverged}       ${tmpl} = ${val}"$'\n'
    fi
  done
  if [[ -n "${diverged}" ]]; then
    echo "ERROR: ${key} diverges across templates (expected ${ref} everywhere):" >&2
    printf '%s' "${diverged}" >&2
    echo "       Fix the manifests, or teach this script to render per-template values." >&2
    return 1
  fi
  printf '%s' "${ref}"
}

# Which templates declare each input. Every template listed in a row's
# "Templates" column must appear here, or that row can state a value only one of
# them actually uses.
all_templates=("${templates[@]}")
scala_templates=(scala-sbt scala-gradle)
kotlin_templates=(kotlin-maven kotlin-gradle)
maven_templates=(java-maven kotlin-maven)
gradle_templates=(scala-gradle java-gradle kotlin-gradle)
java_templates=(scala-gradle java-maven java-gradle kotlin-maven kotlin-gradle)
sbt_templates=(scala-sbt)

gatling_version="$(agreed_default GatlingVersion "${all_templates[@]}")"
picatinny_version="$(agreed_default GatlingPicatinnyVersion "${all_templates[@]}")"
kafka_plugin_version="$(agreed_default KafkaPluginVersion "${all_templates[@]}")"
kafka_streams_version="$(agreed_default KafkaStreamsVersion "${all_templates[@]}")"
jdbc_plugin_version="$(agreed_default JdbcPluginVersion "${all_templates[@]}")"
amqp_plugin_version="$(agreed_default AmqpPluginVersion "${all_templates[@]}")"
postgres_driver_version="$(agreed_default PostgresDriverVersion "${all_templates[@]}")"

name_default="$(agreed_default Name "${all_templates[@]}")"
name_word_default="$(agreed_default NameWord "${all_templates[@]}")"
package_default="$(agreed_default Package "${all_templates[@]}")"
package_path_default="$(agreed_default PackagePath "${all_templates[@]}")"
base_url_default="$(agreed_default BaseUrl "${all_templates[@]}")"
intensity_default="$(agreed_default Intensity "${all_templates[@]}")"

scala_version="$(agreed_default ScalaVersion "${scala_templates[@]}")"
sbt_version="$(agreed_default SbtVersion "${sbt_templates[@]}")"
sbt_gatling_version="$(agreed_default SbtGatlingVersion "${sbt_templates[@]}")"
sbt_scalafmt_version="$(agreed_default SbtScalafmtVersion "${sbt_templates[@]}")"
java_version="$(agreed_default JavaVersion "${java_templates[@]}")"
maven_version="$(agreed_default MavenVersion "${maven_templates[@]}")"
kotlin_version="$(agreed_default KotlinVersion "${kotlin_templates[@]}")"
gradle_wrapper_version="$(agreed_default GradleWrapperVersion "${gradle_templates[@]}")"
gatling_gradle_plugin_version="$(agreed_default GatlingGradlePluginVersion "${gradle_templates[@]}")"
gatling_maven_plugin_version="$(agreed_default GatlingMavenPluginVersion "${maven_templates[@]}")"

# The langtool block states that GatlingGradlePluginVersion tracks the Gatling
# version. Enforce it here so that sentence cannot become a lie.
if [[ "${gatling_gradle_plugin_version}" != "${gatling_version}."* ]]; then
  echo "ERROR: GatlingGradlePluginVersion (${gatling_gradle_plugin_version}) is not on the" >&2
  echo "       ${gatling_version}.x line, but the generated table states that it tracks" >&2
  echo "       GatlingVersion. Bump one of them, or reword the generated sentence." >&2
  exit 1
fi

echo "Pack: ${pack_version} | Gatling: ${gatling_version} | Picatinny: ${picatinny_version}"

# -- Build new block content --------------------------------------------------
# shellcheck disable=SC2034  # consumed indirectly via ${!block_var} below
compat_table_block="<!-- compat-table-start -->
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

# shellcheck disable=SC2034  # consumed indirectly via ${!block_var} below
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

# shellcheck disable=SC2034  # consumed indirectly via ${!block_var} below
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

# shellcheck disable=SC2034  # consumed indirectly via ${!block_var} below
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
# Each block name maps to the shell variable <name-with-underscores>_block, so the
# blocks array is the single source of truth; a name with no matching variable fails
# here under `set -u` instead of surfacing as a Python traceback later.
for block in "${blocks[@]}"; do
  block_var="${block//-/_}_block"
  printf '%s' "${!block_var}" > "${block_dir}/${block}"
done

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
