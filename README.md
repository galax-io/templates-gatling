# templates-gatling

Gatling template pack for `galaxio-cli`.

## Quick Start

```bash
# 1. Install galaxio CLI
curl -fsSL https://raw.githubusercontent.com/galax-io/galaxio-cli/main/scripts/install.sh | sh

# 2. Scaffold a project
galaxio template init gatling/scala-sbt --set Name=my-service -d ./perf-tests

# 3. Compile
cd perf-tests && sbt -batch Gatling/compile
```

Replace `scala-sbt` with any supported template — see [Templates](#templates) below.

## Templates

| Name | Language | Build tool |
| --- | --- | --- |
| `scala-sbt` | Scala | sbt |
| `scala-gradle` | Scala | Gradle |
| `java-maven` | Java | Maven |
| `java-gradle` | Java | Gradle |
| `kotlin-maven` | Kotlin | Maven |
| `kotlin-gradle` | Kotlin | Gradle |

All templates are ready-to-compile Gatling projects. Pick the one matching your
language and build tool.

## Inputs

Each template accepts inputs via `--set Key=Value` or a `--values` YAML file.
Unset inputs fall back to the defaults declared in the template manifest.

### Common inputs (all templates)

| Input | Default | Notes |
| --- | --- | --- |
| `Name` | `myservice` | Project name used in the README and build descriptor. |
| `NameWord` | `myservice` | Name as a valid identifier — used in package/class names. Must not contain spaces or hyphens. |
| `Package` | `org.galaxio.performance` | Base package for generated sources. |
| `PackagePath` | `org/galaxio/performance` | `Package` with dots replaced by `/`. Must stay in sync — see note below. |
| `GatlingVersion` | `3.13.5` | Gatling version injected into the build file. |
| `GatlingPicatinnyVersion` | `1.17.1` | Gatling Picatinny plugin version. |
| `BaseUrl` | `http://localhost` | Target base URL written to `simulation.conf`. |
| `Intensity` | `60 rpm` | Default load intensity written to `simulation.conf`. |

> **`Package` and `PackagePath` must stay in sync.**
> Set both when overriding, or the generated sources will have mismatched
> directory layout and package declarations and will not compile.
>
> ```bash
> galaxio template init gatling/scala-sbt \
>   --set Package=org.example.perf \
>   --set PackagePath=org/example/perf
> ```

> **`Name` vs `NameWord`:** `Name` is a human-readable label (can contain
> hyphens, spaces). `NameWord` is the sanitised identifier used in package and
> class names — it must be a valid Java/Scala/Kotlin identifier. If `Name` is
> `orders-api`, set `NameWord=ordersApi` (or `ordersapi`).
>
> ```bash
> galaxio template init gatling/scala-sbt \
>   --set Name=orders-api \
>   --set NameWord=ordersApi
> ```

### Language and build-tool inputs

These inputs exist only in the templates that use the corresponding language or
build tool.

| Input | Templates | Default |
| --- | --- | --- |
| `ScalaVersion` | `scala-sbt`, `scala-gradle` | `2.13.18` |
| `SbtVersion` | `scala-sbt` | `1.12.13` |
| `JavaVersion` | `java-*`, `kotlin-*`, `scala-gradle` | `17` |
| `MavenVersion` | `java-maven`, `kotlin-maven` | `3.9.16` |
| `KotlinVersion` | `kotlin-maven`, `kotlin-gradle` | `2.4.0` |

Override at render time like any other input:

```bash
galaxio template init gatling/java-maven \
  --set JavaVersion=21 \
  --set MavenVersion=3.9.9 \
  --set Name=orders-api \
  --set NameWord=ordersApi \
  --set Package=org.example.perf \
  --set PackagePath=org/example/perf \
  -d ./perf-tests
```

## Optional Plugin Modules

Each template supports optional Kafka, JDBC, and AMQP plugin modules via
conditional overlay directories. Plugin files live under `plugins/<name>/`
and are rendered only when the corresponding input is enabled.

| Plugin | Enable input | Version input | Default |
| --- | --- | --- | --- |
| Kafka | `KafkaPluginEnabled` | `KafkaPluginVersion` | `1.0.6` |
| JDBC | `JdbcPluginEnabled` | `JdbcPluginVersion` | `1.0.3` |
| AMQP | `AmqpPluginEnabled` | `AmqpPluginVersion` | `1.2.10` |

Enable a plugin at render time:

```bash
galaxio template init gatling/scala-sbt \
  --set KafkaPluginEnabled=true \
  --set Name=my-service \
  --set NameWord=myservice \
  -d ./perf-tests
```

Multiple plugins can be enabled simultaneously:

```bash
galaxio template init gatling/scala-sbt \
  --set KafkaPluginEnabled=true \
  --set JdbcPluginEnabled=true \
  --set AmqpPluginEnabled=true \
  --set Name=my-service \
  --set NameWord=myservice \
  -d ./perf-tests
```

When enabled, each plugin:
- adds its dependency to the build file
- adds connection parameters to `simulation.conf`
- overlays ready-to-run `Actions` and `Scenario` source files

### Plugin connection inputs

| Input | Plugin | Default |
| --- | --- | --- |
| `KafkaUrl` | Kafka | `localhost:9092` |
| `KafkaTopic` | Kafka | `myTopic` |
| `DbUrl` | JDBC | `jdbc:postgresql://localhost:5432/postgres` |
| `DbUser` | JDBC | `postgres` |
| `DbPassword` | JDBC | `postgres` |
| `AmqpHost` | AMQP | `localhost` |
| `AmqpPort` | AMQP | `5672` |
| `AmqpLogin` | AMQP | `guest` |
| `AmqpPassword` | AMQP | `guest` |
| `AmqpQueue` | AMQP | `my_queue` |

### Starter plugin defaults

Generated projects use conservative defaults for JDBC and AMQP so first runs
fail fast on missing infrastructure instead of hanging.

- JDBC `connectionTimeout` — `10 seconds`
- AMQP `replyTimeout` — `10 seconds`
- AMQP `consumerThreadsCount` — `1`

Adjust the generated protocol builders in `Performance.*` for production tuning.

### Plugin directory structure

```text
scala-sbt/
  galaxio-template.yaml
  files/                          # always rendered
    build.sbt
    src/test/scala/...
  plugins/
    kafka/                        # rendered when KafkaPluginEnabled=true
    jdbc/                         # rendered when JdbcPluginEnabled=true
    amqp/                         # rendered when AmqpPluginEnabled=true
```

## Placeholder Syntax

Template files use Go `text/template` syntax. Values are fields on the root
data object:

```text
{{ .Name }}
{{ .Package }}
{{ .PackagePath }}
{{ .NameWord }}
```

Placeholders work in file contents and file paths:

```text
scala-sbt/files/src/test/scala/{{ .PackagePath }}/{{ .NameWord }}/Debug.scala
```

Given:

```yaml
Name: orders-api
NameWord: ordersApi
Package: org.example.performance
PackagePath: org/example/performance
```

the rendered path becomes:

```text
src/test/scala/org/example/performance/ordersApi/Debug.scala
```

Pass values via YAML file or inline `--set` flags. Inline `--set` overrides
YAML:

```bash
galaxio template init gatling/scala-sbt \
  --values .github/template-smoke-values.yaml \
  --set Name=orders-api \
  --set NameWord=ordersApi
```

## Troubleshooting

### Compilation fails with `package does not exist` or `not found: object`

`Package` and `PackagePath` are out of sync. The generated directory layout
does not match the `package` declarations in source files.

Fix: re-render with matching values:

```bash
galaxio template init gatling/scala-sbt \
  --set Package=org.example.perf \
  --set PackagePath=org/example/perf \
  --if-exists overwrite -d ./perf-tests
```

### Compilation fails with `not found: value <NameWord>` or invalid identifier error

`NameWord` contains a character that is not valid in a package/class name
(hyphen, space, dot). Set `NameWord` to a valid Java/Scala/Kotlin identifier.

### Plugin dependency resolution fails

The plugin version may not exist in the public repository or your corporate
mirror is not proxying it. Override the version:

```bash
--set KafkaPluginVersion=0.21.0
```

### Compile fails on a corporate network (artifact mirror)

The generated `build.sbt` / `pom.xml` / `build.gradle` uses public Maven
Central. Configure your build tool to proxy through your corporate mirror after
rendering.

### Template renders but `sbt` / `mvn` / `gradle` is not installed

Install the required build tool for your template before compiling. The CLI
only renders files — it does not install build tooling.

## Pack

The pack manifest is [`galaxio-pack.yaml`](galaxio-pack.yaml).

The CLI resolves the pack `version` field (e.g. `0.15.1`) to GitHub release tag
`v0.15.1` and downloads the release archive at render time. The registry always
points at the repository; the version pins which release is used.

## Compatibility

<!-- compat-table-start -->
> **Auto-generated** — do not edit this block manually. Run `bash .github/scripts/update-readme-compat.sh` to refresh.

### Render-time vs runtime versions

**Pack version** (`0.15.1`) is render-time metadata: `galaxio-cli` resolves this
version when you run `galaxio template init gatling/<template>` and downloads the matching pack
from the registry.

**Gatling** and **Picatinny** versions are *default runtime dependency values* injected into the
generated project's build file. Override any of them at render time with `--set Flag=value`:

```bash
galaxio template init gatling/scala-sbt \
  --set GatlingVersion=3.14.0 \
  --set GatlingPicatinnyVersion=1.13.0
```

The pack uses `apiVersion: galaxio.io/v1`. Consult the
[galaxio-cli releases](https://github.com/galax-io/galaxio-cli/releases) for the minimum
compatible CLI version.

### Version table

Pack `0.15.1` · Gatling `3.13.5` · Picatinny `1.17.1`

| Template | Language | Build tool | Template version | Gatling | Picatinny |
|---|---|---|---|---|---|
| `scala-sbt` | Scala | sbt | `0.3.1` | `3.13.5` | `1.17.1` |
| `scala-gradle` | Scala | Gradle | `0.3.1` | `3.13.5` | `1.17.1` |
| `java-maven` | Java | Maven | `0.3.0` | `3.13.5` | `1.17.1` |
| `java-gradle` | Java | Gradle | `0.3.1` | `3.13.5` | `1.17.1` |
| `kotlin-maven` | Kotlin | Maven | `0.3.0` | `3.13.5` | `1.17.1` |
| `kotlin-gradle` | Kotlin | Gradle | `0.3.1` | `3.13.5` | `1.17.1` |

All templates share the same Gatling and Picatinny defaults; the script validates this on every run.
See [`galaxio-pack.yaml`](galaxio-pack.yaml) for the authoritative template version list.
<!-- compat-table-end -->

## Developing Templates

Each template lives in its own directory:

```text
scala-sbt/
  galaxio-template.yaml
  files/
    build.sbt
    src/test/scala/{{ .PackagePath }}/{{ .NameWord }}/Debug.scala
  plugins/
    kafka/
    jdbc/
    amqp/
```

The pack manifest registers templates in [`galaxio-pack.yaml`](galaxio-pack.yaml).
Renderable templates must define a `path` and contain a `galaxio-template.yaml`.
Placeholder-only templates omit `path` and appear as "coming soon" in the CLI.

Plugin overlay directories are declared in the template manifest:

```yaml
files:
  - from: files
    to: .
  - from: plugins/kafka
    to: .
    if: '{{ .KafkaPluginEnabled }}'
```

For local development, create a temporary registry pointing at this checkout:

```bash
tmpdir="$(mktemp -d)"
mkdir -p "$tmpdir/registry"
cat > "$tmpdir/registry/galaxio-registry.yaml" <<YAML
apiVersion: galaxio.io/v1
kind: TemplateRegistry
packs:
  - name: gatling
    source: local:$(pwd)
YAML

export GALAXIO_CONFIG="$tmpdir/galaxio-config.yaml"
galaxio template configure --registry "local:$tmpdir/registry"
galaxio template validate local:.
galaxio template init gatling/scala-sbt \
  --destination "$tmpdir/scala-sbt" \
  --values .github/template-smoke-values.yaml
```

After rendering, compile with the selected build tool:

```bash
cd "$tmpdir/scala-sbt"
sbt -batch Gatling/compile
```

### Integration tests

Integration tests for JDBC, AMQP, and Kafka plugins require Docker.
CI runs them automatically. To run locally:

```bash
bash .github/scripts/run-integration-test.sh kafka
bash .github/scripts/run-integration-test.sh jdbc
bash .github/scripts/run-integration-test.sh amqp
```

Each script renders the template with the plugin enabled, starts the required
Docker Compose stack, runs the Gatling scenario, and verifies output.

### Versioning

When changing files under a renderable template directory, bump both:
- top-level pack `version`
- `templates[].version` for the changed template

Versioning rule:
- `fix`: patch bump — `0.2.0 → 0.2.1`
- `feat`: minor bump — `0.2.0 → 0.3.0`
- new renderable templates start from `0.1.0`

CI enforces `fix` vs `feat` bump policy and verifies that the new pack version
is not already tagged.

Run the versioning checker self-test locally:

```bash
bash .github/scripts/check-template-version-bump_test.sh
```

## Release

Releases are tag-driven. After merging to `main`:

1. Push a tag matching the pack version: `git tag v0.15.1 && git push origin v0.15.1`
2. The release workflow creates a GitHub Release with auto-generated notes.
3. The workflow validates that the tag matches `version` in `galaxio-pack.yaml`.

## Validation

CI installs `galaxio`, validates the pack manifest, configures a local registry,
renders each template through `galaxio template init` with default values,
checks placeholder substitution, and compiles the rendered project.

When a template has `plugins/kafka/`, CI also renders with `KafkaPluginEnabled=true`,
verifies plugin source files are present (and absent in the default render),
checks for the plugin dependency in the build file, and compiles the
kafka-enabled project.
