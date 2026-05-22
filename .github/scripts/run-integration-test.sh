#!/usr/bin/env bash
# Integration test: render scala-sbt with a plugin enabled and run the
# Debug simulation against real services (PostgreSQL, RabbitMQ, Redpanda).
#
# Usage:
#   run-integration-test.sh <plugin>
#
#   plugin — jdbc | amqp | kafka
#
# Expects:
#   - galaxio binary on PATH
#   - sbt on PATH (or available via SDKMAN)
#   - Docker services already running (started by CI or docker-compose up)
#
# Environment:
#   RUNNER_TEMP         — temp directory (default: mktemp -d)
#   GITHUB_WORKSPACE    — repo root (default: detected from script path)
#   GITHUB_STEP_SUMMARY — optional step summary file for CI
set -euo pipefail

plugin="${1:?plugin name required: jdbc | amqp | kafka}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workspace_root="${GITHUB_WORKSPACE:-${repo_root}}"
runner_temp="${RUNNER_TEMP:-$(mktemp -d)}"
values_file="${workspace_root}/.github/template-smoke-values.yaml"
registry_root="${runner_temp}/registry-integration"
config_file="${runner_temp}/galaxio-config-integration.yaml"
render_dir="${runner_temp}/integration/${plugin}"
compile_log="${render_dir}/compile.log"
run_log="${render_dir}/run.log"
start_time="$(date +%s)"
template="scala-sbt"

# -- Map plugin to template flags and JVM overrides -----------------------
case "${plugin}" in
  jdbc)
    plugin_flag="JdbcPluginEnabled"
    jvm_overrides=(
      "-DbaseUrl=http://localhost:8080"
      "-DdbUrl=jdbc:postgresql://localhost:5432/postgres"
      "-DdbUser=postgres"
      "-DdbPassword=postgres"
      "-DtestDuration=10 seconds"
    )
    ;;
  amqp)
    plugin_flag="AmqpPluginEnabled"
    jvm_overrides=(
      "-DbaseUrl=http://localhost:8080"
      "-DamqpHost=localhost"
      "-DamqpPort=5672"
      "-DamqpLogin=guest"
      "-DamqpPassword=guest"
      "-DamqpQueue=integration_test_queue"
      "-DtestDuration=10 seconds"
    )
    ;;
  kafka)
    plugin_flag="KafkaPluginEnabled"
    jvm_overrides=(
      "-DbaseUrl=http://localhost:8080"
      "-DkafkaUrl=localhost:9092"
      "-DkafkaTopic=integration_test_topic"
      "-DtestDuration=10 seconds"
    )
    ;;
  *)
    echo "Unknown plugin: ${plugin}. Expected: jdbc | amqp | kafka" >&2
    exit 1
    ;;
esac

echo "=== Integration test: ${template} + ${plugin} ==="
echo "Render dir: ${render_dir}"

# -- Render template with plugin enabled ----------------------------------
mkdir -p "${registry_root}" "${render_dir}"

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
  --destination "${render_dir}" \
  --values "${values_file}" \
  --set "${plugin_flag}=true"

echo "Template rendered."

# -- Compile the rendered project -----------------------------------------
echo "Compiling..."
set +e
(
  cd "${render_dir}"
  set -o pipefail
  sbt -batch Gatling/compile 2>&1 | tee "${compile_log}"
)
compile_status=$?
set -e

if [[ "${compile_status}" -ne 0 ]]; then
  echo "FAIL: compilation failed for ${template}+${plugin}" >&2
  cat "${compile_log}" >&2
  exit 1
fi

echo "Compilation succeeded."

# -- Wait for required services -------------------------------------------
wait_for_port() {
  local host="$1" port="$2" name="$3" retries="${4:-30}"
  echo "Waiting for ${name} on ${host}:${port}..."
  for (( i=1; i<=retries; i++ )); do
    if nc -z "${host}" "${port}" 2>/dev/null; then
      echo "${name} is ready."
      return 0
    fi
    sleep 2
  done
  echo "FAIL: ${name} not reachable on ${host}:${port} after $((retries * 2))s" >&2
  return 1
}

wait_for_port localhost 8080 "HTTP mock"
case "${plugin}" in
  jdbc)  wait_for_port localhost 5432 "PostgreSQL" ;;
  amqp)  wait_for_port localhost 5672 "RabbitMQ" ;;
  kafka) wait_for_port localhost 9092 "Redpanda/Kafka" ;;
esac

# -- Run the Debug simulation against real services -----------------------
echo "Running Debug simulation with ${plugin} plugin..."
set +e
(
  cd "${render_dir}"
  set -o pipefail
  sbt -batch \
    "${jvm_overrides[@]}" \
    "Gatling/testOnly org.example.performance.ordersapi.Debug" \
    2>&1 | tee "${run_log}"
)
run_status=$?
set -e

# -- Report results -------------------------------------------------------
duration="$(( $(date +%s) - start_time ))"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Integration: ${template} + ${plugin}"
    echo
    echo "- Duration: \`${duration}s\`"
    if [[ "${run_status}" -eq 0 ]]; then
      echo "- Result: **success**"
    else
      echo "- Result: **failure**"
    fi
    echo
  } >> "${GITHUB_STEP_SUMMARY}"
fi

if [[ "${run_status}" -ne 0 ]]; then
  echo "FAIL: Debug simulation failed for ${template}+${plugin}" >&2
  echo "--- Run log (last 50 lines) ---" >&2
  tail -50 "${run_log}" >&2
  exit 1
fi

echo "=== Integration test PASSED: ${template} + ${plugin} (${duration}s) ==="
