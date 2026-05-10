#!/usr/bin/env bash
set -euo pipefail

template="${1:?template name is required}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workspace_root="${GITHUB_WORKSPACE:-${repo_root}}"
runner_temp="${RUNNER_TEMP:-$(mktemp -d)}"
values_file="${workspace_root}/.github/template-smoke-values.yaml"
registry_root="${runner_temp}/registry"
config_file="${runner_temp}/galaxio-config.yaml"
render_root="${runner_temp}/rendered/${template}"
default_dir="${render_root}/default"
override_dir="${render_root}/override"
kafka_dir="${render_root}/kafka"
compile_log="${render_root}/compile.log"
start_time="$(date +%s)"

expected_picatinny_version="$(awk -F': ' '$1 == "GatlingPicatinnyVersion" { print $2 }' "${values_file}")"

case "${template}" in
  scala-sbt)
    build_tool="sbt"
    source_root="src/test/scala"
    debug_file="${source_root}/org/example/performance/ordersapi/Debug.scala"
    override_debug_file="${source_root}/org/example/performance/ordersapiset/Debug.scala"
    stability_file="${source_root}/org/example/performance/ordersapi/Stability.scala"
    max_performance_file="${source_root}/org/example/performance/ordersapi/MaxPerformance.scala"
    build_file="build.sbt"
    picatinny_file="project/Dependencies.scala"
    picatinny_needle="gatling-picatinny\" % \"${expected_picatinny_version}\""
    wrapper_file=""
    compile_cmd="sbt -batch Gatling/compile"
    override_name="orders-api-set"
    override_name_word="ordersapiset"
    ;;
  scala-gradle)
    build_tool="gradle"
    source_root="src/gatling/scala"
    debug_file="${source_root}/org/example/performance/ordersapi/Debug.scala"
    override_debug_file="${source_root}/org/example/performance/ordersapigradle/Debug.scala"
    stability_file="${source_root}/org/example/performance/ordersapi/Stability.scala"
    max_performance_file="${source_root}/org/example/performance/ordersapi/MaxPerformance.scala"
    build_file="build.gradle"
    picatinny_file="build.gradle"
    picatinny_needle="gatling-picatinny_2.13:${expected_picatinny_version}"
    wrapper_file="gradlew"
    compile_cmd="./gradlew --no-daemon gatlingClasses"
    override_name="orders-api-gradle"
    override_name_word="ordersapigradle"
    ;;
  java-maven)
    build_tool="maven"
    source_root="src/test/java"
    debug_file="${source_root}/org/example/performance/ordersapi/Debug.java"
    override_debug_file="${source_root}/org/example/performance/ordersapijavamaven/Debug.java"
    stability_file="${source_root}/org/example/performance/ordersapi/Stability.java"
    max_performance_file="${source_root}/org/example/performance/ordersapi/MaxPerformance.java"
    build_file="pom.xml"
    picatinny_file="pom.xml"
    picatinny_needle="<picatinny.version>${expected_picatinny_version}</picatinny.version>"
    wrapper_file="mvnw"
    compile_cmd="./mvnw -q test-compile"
    override_name="orders-api-java-maven"
    override_name_word="ordersapijavamaven"
    ;;
  kotlin-maven)
    build_tool="maven"
    source_root="src/test/kotlin"
    debug_file="${source_root}/org/example/performance/ordersapi/Debug.kt"
    override_debug_file="${source_root}/org/example/performance/ordersapikotlinmaven/Debug.kt"
    stability_file="${source_root}/org/example/performance/ordersapi/Stability.kt"
    max_performance_file="${source_root}/org/example/performance/ordersapi/MaxPerformance.kt"
    build_file="pom.xml"
    picatinny_file="pom.xml"
    picatinny_needle="<picatinny.version>${expected_picatinny_version}</picatinny.version>"
    wrapper_file="mvnw"
    compile_cmd="./mvnw -q test-compile"
    override_name="orders-api-kotlin-maven"
    override_name_word="ordersapikotlinmaven"
    ;;
  java-gradle)
    build_tool="gradle"
    source_root="src/gatling/java"
    debug_file="${source_root}/org/example/performance/ordersapi/Debug.java"
    override_debug_file="${source_root}/org/example/performance/ordersapijavagradle/Debug.java"
    stability_file="${source_root}/org/example/performance/ordersapi/Stability.java"
    max_performance_file="${source_root}/org/example/performance/ordersapi/MaxPerformance.java"
    build_file="build.gradle"
    picatinny_file="build.gradle"
    picatinny_needle="gatling-picatinny_2.13:${expected_picatinny_version}"
    wrapper_file="gradlew"
    compile_cmd="./gradlew --no-daemon gatlingClasses"
    override_name="orders-api-java-gradle"
    override_name_word="ordersapijavagradle"
    ;;
  kotlin-gradle)
    build_tool="gradle"
    source_root="src/gatling/kotlin"
    debug_file="${source_root}/org/example/performance/ordersapi/Debug.kt"
    override_debug_file="${source_root}/org/example/performance/ordersapikotlingradle/Debug.kt"
    stability_file="${source_root}/org/example/performance/ordersapi/Stability.kt"
    max_performance_file="${source_root}/org/example/performance/ordersapi/MaxPerformance.kt"
    build_file="build.gradle.kts"
    picatinny_file="build.gradle.kts"
    picatinny_needle="gatling-picatinny_2.13:${expected_picatinny_version}"
    wrapper_file="gradlew"
    compile_cmd="./gradlew --no-daemon gatlingClasses"
    override_name="orders-api-kotlin-gradle"
    override_name_word="ordersapikotlingradle"
    ;;
  *)
    echo "Unsupported template: ${template}" >&2
    exit 1
    ;;
esac

source_ext="${debug_file##*.}"
kafka_actions_file="${source_root}/org/example/performance/ordersapi/cases/KafkaActions.${source_ext}"
kafka_scenario_file="${source_root}/org/example/performance/ordersapi/scenarios/KafkaScenario.${source_ext}"
plugin_source_dir="${workspace_root}/${template}/plugins/kafka"

mkdir -p "${registry_root}" "${default_dir}" "${override_dir}"
rm -f "${compile_log}"

cat > "${registry_root}/galaxio-registry.yaml" <<EOF
apiVersion: galaxio.io/v1
kind: TemplateRegistry
packs:
  - name: gatling
    source: local:${workspace_root}
EOF

export GALAXIO_CONFIG="${config_file}"

galaxio template configure --registry "local:${registry_root}" >/dev/null
galaxio template init "gatling/${template}" \
  --destination "${default_dir}" \
  --values "${values_file}"

galaxio template init "gatling/${template}" \
  --destination "${override_dir}" \
  --values "${values_file}" \
  --set "Name=${override_name}" \
  --set "NameWord=${override_name_word}"

grep -R "${override_name}" "${override_dir}" >/dev/null
test -f "${override_dir}/${override_debug_file}"

test -f "${default_dir}/${build_file}"
test -f "${default_dir}/${debug_file}"
grep -R "orders-api" "${default_dir}" >/dev/null
grep -R "org.example.performance" "${default_dir}/${source_root}" >/dev/null
grep -R "${picatinny_needle}" "${default_dir}/${picatinny_file}" >/dev/null
grep -R "Utility.banner(" "${default_dir}/${stability_file}" >/dev/null
grep -R "Utility.banner(" "${default_dir}/${max_performance_file}" >/dev/null

if [[ -n "${wrapper_file}" ]]; then
  test -f "${default_dir}/${wrapper_file}"
  chmod +x "${default_dir}/${wrapper_file}"
fi

set +e
(
  cd "${default_dir}"
  set -o pipefail
  eval "${compile_cmd}" 2>&1 | tee "${compile_log}"
)
compile_status=$?
set -e

# -- plugin smoke (only when template ships plugin overlays) -----------
kafka_compile_status=0
if [[ -d "${plugin_source_dir}" ]]; then
  mkdir -p "${kafka_dir}"

  galaxio template init "gatling/${template}" \
    --destination "${kafka_dir}" \
    --values "${values_file}" \
    --set "KafkaPluginEnabled=true"

  # plugin files must appear when enabled
  test -f "${kafka_dir}/${kafka_actions_file}"
  test -f "${kafka_dir}/${kafka_scenario_file}"

  # plugin files must be absent in default render (no leakage)
  test ! -f "${default_dir}/${kafka_actions_file}"
  test ! -f "${default_dir}/${kafka_scenario_file}"

  # build file must reference kafka plugin dep
  grep -R "gatling-kafka-plugin" "${kafka_dir}/${picatinny_file}" >/dev/null

  if [[ -n "${wrapper_file}" ]]; then
    chmod +x "${kafka_dir}/${wrapper_file}"
  fi

  set +e
  (
    cd "${kafka_dir}"
    set -o pipefail
    eval "${compile_cmd}" 2>&1 | tee -a "${compile_log}"
  )
  kafka_compile_status=$?
  set -e
fi

duration="$(( $(date +%s) - start_time ))"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### ${template}"
    echo
    echo "- Build tool: \`${build_tool}\`"
    echo "- Compile command: \`${compile_cmd}\`"
    echo "- Default render: \`${default_dir}\`"
    echo "- Override render: \`${override_dir}\`"
    echo "- Compile log: \`${compile_log}\`"
    echo "- Duration: \`${duration}s\`"
    if [[ "${compile_status}" -eq 0 ]]; then
      echo "- Result: success"
    else
      echo "- Result: failure"
    fi
    if [[ -d "${plugin_source_dir}" ]]; then
      if [[ "${kafka_compile_status}" -eq 0 ]]; then
        echo "- Kafka plugin: success"
      else
        echo "- Kafka plugin: failure"
      fi
    fi
    echo
  } >> "${GITHUB_STEP_SUMMARY}"
fi

if [[ "${compile_status}" -ne 0 ]] || [[ "${kafka_compile_status}" -ne 0 ]]; then
  exit 1
fi
