<!--
Sync Impact Report
- Version change: (template) -> 1.0.0
- Bump rationale: MAJOR, first ratified constitution of templates-gatling.
- Sections: Precedence; Core Principles (I. Template inputs are public API,
  II. Every template change is versioned, III. Six templates in parity,
  IV. Every template renders, compiles and runs, V. Derived documentation is generated,
  VI. Releases are immutable tags of the pack version, VII. Safe, resolvable defaults);
  Contracts with Consumers and Dependencies; Development Workflow and Quality Gates; Governance.
- Templates checked: .specify/templates/plan-template.md (Constitution Check reads the
  principles below; no change needed), .specify/templates/spec-template.md,
  .specify/templates/tasks-template.md (no change needed).
- Follow-up TODOs: none.
-->

# templates-gatling Constitution

`templates-gatling` is the `gatling` template pack that `galaxio-cli` renders with
`galaxio template init gatling/<template>`: six Gatling projects (`scala-sbt`, `scala-gradle`,
`java-gradle`, `java-maven`, `kotlin-gradle`, `kotlin-maven`), each with a base `files/` tree and
optional `plugins/kafka`, `plugins/jdbc` and `plugins/amqp` overlays. What it ships is not code
that runs here but projects that run on users' machines, so its invariants are about what a
render produces.

## Precedence

1. The maintainer's direct instruction.
2. The ecosystem constitution (`galax-io/galaxio-sdlc-backlog`, `.specify/memory/constitution.md`).
3. This constitution.
4. `AGENTS.md` of this repository (the working guide: commands, structure).

This constitution MAY tighten the ecosystem principles and MUST NOT contradict them. Where
`AGENTS.md` conflicts with it, this constitution wins.

## Core Principles

### I. Template inputs are public API

- The `inputs:` of every `*/galaxio-template.yaml` are a user-facing contract: users pass them by
  `--set Key=Value` and `--values` files. An existing input MUST NOT be renamed or removed, and
  its meaning MUST NOT change (`AGENTS.md`, "Never").
- New behaviour MUST be added as a new input whose default keeps the previous render unchanged
  (for example `*PluginEnabled` defaults to `"false"`).
- The coupled pairs `Package`/`PackagePath` and `Name`/`NameWord` keep their documented
  semantics in `README.md`; a template MUST NOT derive one from the other in a way that changes
  existing renders.

Rationale: scripts, CI pipelines and values files of users depend on these names; a rename
breaks them silently at render time.

### II. Every template change is versioned

- A change to any file under a renderable template's `path` MUST bump the pack `version` and that
  template's `templates[].version` in `galaxio-pack.yaml`: `feat` -> minor, `fix` -> patch; a new
  renderable template starts at `0.1.0`.
- The commit subject of such a change MUST start with `feat` or `fix`, since
  `.github/scripts/check-template-version-bump.sh` decides the bump from it.
- A pack version MUST NOT be one that is already tagged (`v<version>`).

Rationale: `galaxio-cli` resolves the pack `version` to the release tag `v<version>` and
downloads that archive; an unbumped change is unreachable for users or overwrites what a pinned
version means. Enforced by the `versioning` CI job.

### III. Six templates in parity

- Every template MUST declare the inputs shared by all six with the same defaults (Gatling,
  Picatinny, the three plugin versions, `PostgresDriverVersion`, `KafkaStreamsVersion`); an input
  specific to a language or build tool MUST have the same default in every template that declares
  it. `.github/scripts/update-readme-compat.sh` fails on divergence.
- Every template MUST ship the `kafka`, `jdbc` and `amqp` overlays under `plugins/<name>/`, wired
  in `files:` with `if: '{{ .<Name>PluginEnabled }}'`; plugin files MUST NOT appear in a render
  with the plugin disabled.
- A change of behaviour or default in one template MUST be made in all six, or the spec MUST say
  why one is excluded.

Rationale: users pick a template by language and build tool, not by feature set; the README and
compatibility table promise the same project in each.

### IV. Every template renders, compiles and runs

- A change MUST NOT be merged unless `galaxio template validate local:.` passes and the
  `template-smoke` job of every affected template passes: default, override and Kafka renders,
  placeholder checks, and the `Debug` simulation run against WireMock
  (`.github/scripts/run-template-smoke.sh`).
- A change to a plugin overlay MUST keep `integration-<plugin>` green
  (`.github/scripts/run-integration-test.sh`, services from `.github/integration/docker-compose.yml`).
- A new default version MUST be reflected in `.github/template-smoke-values.yaml` in the same
  change, and every version there MUST resolve from Maven Central.

Rationale: a broken template is only discovered when a user runs `init`; the smoke and
integration jobs are the only place the rendered projects are executed before release.

### V. Derived documentation is generated

- The `README.md` blocks between `<!-- compat-table-start -->`, `<!-- inputs-common-start -->`,
  `<!-- inputs-langtool-start -->`, `<!-- inputs-plugins-start -->` and their `-end` markers MUST
  be produced by `.github/scripts/update-readme-compat.sh` from `galaxio-pack.yaml` and the
  template manifests, never edited by hand.
- A change to a version or a shared default MUST regenerate them in the same change.

Rationale: the hand-maintained tables drifted from the manifests; CI (`versioning`) now fails when
the regenerated README differs.

### VI. Releases are immutable tags of the pack version

- A release is a tag `vX.Y.Z` equal to `version` in `galaxio-pack.yaml`, on `main` or a
  `release/X.Y` branch (`.github/workflows/release.yml` refuses anything else).
- There is one `release/X.Y` branch per minor; patches of a released minor reach it by
  cherry-pick.
- A released tag MUST NOT be deleted, moved or re-pointed; a correction is a new patch version.
- Release notes come from Conventional Commits through `cliff.toml`; commit subjects MUST be
  conventional so they are not filtered out.

Rationale: `galaxio-cli` users pin pack versions; a moved tag changes the projects a pinned
version renders.

### VII. Safe, resolvable defaults

- Default endpoints and credentials (`BaseUrl`, `DbUrl`, `DbUser`, `DbPassword`, `AmqpLogin`,
  `AmqpPassword`, `KafkaUrl` and the like) MUST stay local placeholders (`localhost`, `postgres`,
  `guest`); a template MUST NOT carry a real host, credential or token.
- Generated projects MUST resolve their dependencies from public repositories (Maven Central, plus
  `packages.confluent.io` where the Kafka overlay declares it) without private mirrors.
- Starter plugin settings MUST fail fast on missing infrastructure (JDBC `connectionTimeout` and
  AMQP `replyTimeout` of `10 seconds`, AMQP `consumerThreadsCount` of `1`) unless a spec changes
  them deliberately.

Rationale: rendered projects are copied into users' repositories and run on first try; a leaked or
hanging default spreads to every project made from the pack.

## Contracts with Consumers and Dependencies

- **galaxio-cli** renders the pack. The manifests use `apiVersion: galaxio.io/v1`, `kind:
  TemplatePack` / `Template` and `engine: go-template`. A manifest field or template syntax the
  CLI does not support MUST NOT be introduced before a released `galaxio-cli` supports it; CI
  builds the CLI at the tag pinned in `.github/workflows/ci.yml`, and raising that pin is a
  deliberate change.
- **gatling-picatinny, gatling-kafka-plugin, gatling-jdbc-plugin, gatling-amqp-plugin,
  sbt-schema-registry-plugin** (`catalog-info.yaml` `dependsOn`) are consumed through the inputs
  `GatlingPicatinnyVersion`, `KafkaPluginEnabled`/`Version`, `JdbcPluginEnabled`/`Version`,
  `AmqpPluginEnabled`/`Version`. A default MUST point to a released version of that library, and a
  breaking change in one of them is adopted here as a versioned `feat` of the pack.
- Every template's `logback.xml` MUST bind the `org.galaxio.gatling.diagnostics` logger, which the
  Picatinny startup banner and diagnostics write to; the smoke run fails without it.
- **spec-kit-galaxio-bootstrap** supplies the process files; the kit under `.claude/skills`,
  `.agents/skills` and `.specify/` (except `.specify/memory/`) MUST stay byte-identical to
  `.specify/speckit-kit.sha256` (`scripts/check-speckit.sh`) and is changed only through that
  template.
- A change to these relations MUST update `catalog-info.yaml` in the same change.

## Development Workflow and Quality Gates

- Work enters through the backlog: every PR carries a milestone of this repository and
  `Part of galax-io/galaxio-sdlc-backlog#<feature>`; `scripts/check-linkage.sh --pr` (the
  `linkage` workflow) enforces it.
- Required gates for a PR that touches templates: `lint` (shellcheck of `.github/scripts/*.sh`,
  actionlint), `versioning`, `pack-validate`, `template-smoke` for each affected template,
  `integration` for jdbc, amqp and kafka, `speckit`, `linkage`.
- `main` is never pushed to directly or force-pushed; branches are rebased, not merged.
- Asking the maintainer first is required for a new template, a new plugin overlay, or a change to
  the release workflow (`AGENTS.md`, "Ask first").
- A change to a gate script (`check-template-version-bump.sh`, `check-linkage.sh`,
  `check-speckit.sh`, the pre-push hook) MUST keep or extend its `_test.sh` suite.

## Governance

- This constitution is amended by a pull request to this repository with the maintainer's explicit
  approval. The amendment updates the Sync Impact Report at the top of this file.
- The constitution is versioned by semver: MAJOR for removing or redefining a principle, MINOR for
  adding a principle or section or materially expanding one, PATCH for wording that does not change
  what is allowed.
- Specs and plans that touch this repository MUST pass the Constitution Check of
  `.specify/templates/plan-template.md` against these principles. An exception MUST be recorded in
  the plan's Complexity Tracking with an owner and a removal date.

**Version**: 1.0.0 | **Ratified**: 2026-10-20 | **Last Amended**: 2026-10-20
