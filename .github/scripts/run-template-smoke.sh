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

expected_picatinny_version="$(awk -F': ' '$1 == "GatlingPicatinnyVersion" { print $2 }' "${values_file}")"

case "${template}" in
  scala-sbt)
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

mkdir -p "${registry_root}" "${default_dir}" "${override_dir}"

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

(
  cd "${default_dir}"
  eval "${compile_cmd}"
)
