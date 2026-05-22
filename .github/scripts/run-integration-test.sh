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
#   - Docker services already running and healthy (started by CI via
#     docker compose up --wait)
#
# Environment:
#   RUNNER_TEMP         — temp directory (default: mktemp -d)
#   GITHUB_WORKSPACE    — repo root (default: detected from script path)
#   GITHUB_STEP_SUMMARY — optional step summary file for CI
#   COMPOSE_FILE        — docker-compose file path (default: detected)
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
compose_file="${COMPOSE_FILE:-${workspace_root}/.github/integration/docker-compose.yml}"
start_time="$(date +%s)"
template="scala-sbt"

# -- Map plugin to template flags and JVM overrides -----------------------
case "${plugin}" in
  jdbc)
    plugin_flag="JdbcPluginEnabled"
    render_overrides=()
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
    render_overrides=("AmqpQueue=integration_test_queue")
    jvm_overrides=(
      "-DbaseUrl=http://localhost:8080"
      "-DamqpHost=localhost"
      "-DamqpPort=5672"
      "-DamqpLogin=guest"
      "-DamqpPassword=guest"
      "-DtestDuration=10 seconds"
    )
    ;;
  kafka)
    plugin_flag="KafkaPluginEnabled"
    render_overrides=("KafkaTopic=integration_test_topic" "KafkaUrl=localhost:9092")
    jvm_overrides=(
      "-DbaseUrl=http://localhost:8080"
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

render_args=(
  "gatling/${template}"
  --destination "${render_dir}"
  --values "${values_file}"
  --set "${plugin_flag}=true"
)
for override in "${render_overrides[@]}"; do
  render_args+=(--set "${override}")
done
galaxio template init "${render_args[@]}"

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

# -- Pre-provision service resources --------------------------------------
# Services are expected to be healthy already (docker compose up --wait).
# Some plugins need resources (queues, topics) declared before the first
# publish so the broker doesn't silently drop messages.
case "${plugin}" in
  amqp)
    echo "Declaring AMQP queue 'integration_test_queue'..."
    docker compose -f "${compose_file}" exec -T rabbitmq \
      rabbitmqadmin declare queue name=integration_test_queue durable=false
    ;;
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

if [[ "${run_status}" -ne 0 ]]; then
  echo "FAIL: Debug simulation failed for ${template}+${plugin}" >&2
  echo "--- Run log (last 50 lines) ---" >&2
  tail -50 "${run_log}" >&2
  exit 1
fi

# -- Post-run verification ------------------------------------------------
# Check that the plugin actually communicated with the service, not just
# that the Gatling process exited 0.
case "${plugin}" in
  jdbc)
    echo "Verifying JDBC: checking table 'mytable' exists in PostgreSQL..."
    docker compose -f "${compose_file}" exec -T postgres \
      psql -U postgres -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'mytable')" \
      | grep -q "t"
    echo "JDBC verification: table 'mytable' exists."
    ;;
  amqp)
    echo "Verifying AMQP: checking queue 'integration_test_queue' received messages..."
    msg_count=$(docker compose -f "${compose_file}" exec -T rabbitmq \
      rabbitmqctl list_queues name messages --formatter json \
      | python3 -c "import sys,json; qs=json.load(sys.stdin); print(next((q['messages'] for q in qs if q['name']=='integration_test_queue'), 0))")
    if [[ "${msg_count}" -gt 0 ]]; then
      echo "AMQP verification: queue has ${msg_count} message(s)."
    else
      echo "FAIL: AMQP verification — queue 'integration_test_queue' has 0 messages." >&2
      exit 1
    fi
    ;;
  kafka)
    echo "Verifying Kafka: checking messages were produced to 'integration_test_topic'..."
    hwm=$(docker compose -f "${compose_file}" exec -T redpanda \
      rpk topic describe integration_test_topic 2>/dev/null \
      | awk '
          /HIGH-WATERMARK/ { for(i=1;i<=NF;i++) if($i=="HIGH-WATERMARK") col=i; found=1; next }
          found && /^[0-9]/ { print $col+0; exit }
        ')
    if [[ "${hwm:-0}" -gt 0 ]]; then
      echo "Kafka verification: high-water mark = ${hwm} (messages produced)."
    else
      echo "FAIL: Kafka verification — high-water mark is 0, no messages on topic 'integration_test_topic'." >&2
      exit 1
    fi
    ;;
esac

# -- Report results -------------------------------------------------------
duration="$(( $(date +%s) - start_time ))"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Integration: ${template} + ${plugin}"
    echo
    echo "- Duration: \`${duration}s\`"
    echo "- Result: **success** (verified)"
    echo
  } >> "${GITHUB_STEP_SUMMARY}"
fi

echo "=== Integration test PASSED: ${template} + ${plugin} (${duration}s) ==="
