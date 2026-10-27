# templates-gatling — Agent Guide

Gatling performance testing template pack for galaxio CLI (Go template engine, Gatling 3.13.x, Scala 2.13 / Java 17 / Kotlin 2.x). Six templates (scala-sbt, scala-gradle, java-gradle, java-maven, kotlin-gradle, kotlin-maven) — each ships a base simulation set plus optional kafka/jdbc/amqp plugin overlays. Prefer additive changes; template inputs are user-facing API.

CLI repo: https://github.com/galax-io/galaxio-cli (`cmd/galaxio/template.go` — how `init` resolves pack → renders `files/` → merges plugin overlays)

**Constitution:** the principles of this repository are in `.specify/memory/constitution.md`; where they conflict with this file, the constitution wins.

## Commands

```bash
# Local setup: register local pack (once per working copy), render a project.
galaxio template configure --registry "local:$(pwd)"
galaxio template init "gatling/scala-sbt" --destination ./out \
  --values .github/template-smoke-values.yaml --set KafkaPluginEnabled=true

# Versioning gate: feat→minor, fix→patch. Run before committing.
bash .github/scripts/check-template-version-bump.sh

# Smoke: render template, verify expected files, run Debug simulation vs WireMock (Docker + galaxio on PATH).
bash .github/scripts/run-template-smoke.sh scala-sbt   # any of the 6 template names

# Integration: render scala-sbt with plugin, compile, run Debug simulation vs real services.
# Services: WireMock + Postgres + RabbitMQ + Redpanda (docker-compose.yml in .github/integration/).
docker compose -f .github/integration/docker-compose.yml up -d --wait
bash .github/scripts/run-integration-test.sh kafka   # or: jdbc | amqp
docker compose -f .github/integration/docker-compose.yml down

# Release: v* tag triggers CI — validates tag is on main or release/* branch,
# tag == galaxio-pack.yaml version, then creates GitHub release.
# One release/X.Y branch per minor (e.g. release/0.15). Never delete a released tag.
# Patch on existing minor:
git checkout release/0.15 && git cherry-pick <sha>
# bump galaxio-pack.yaml version, then:
git tag v0.15.1 && git push origin release/0.15 v0.15.1
# New minor/major — cut branch from main, tag:
git checkout -b release/0.16 main && git push -u origin release/0.16
git tag v0.16.0 && git push origin v0.16.0
```

## Boundaries

**Always:** bump pack version and all template versions on every change, keep `.github/template-smoke-values.yaml` in sync with new default versions, use semantic commit prefixes (`feat:` → minor, `fix:` → patch).

**Ask first:** new template, new plugin overlay, release workflow changes.

**Never:** force-push or commit to `main`, rename/remove existing inputs, commit broken templates, use versions not on Maven Central in `template-smoke-values.yaml`.

## Feature milestones (ALWAYS)

A feature is an issue in `galax-io/galaxio-sdlc-backlog`. It belongs to exactly one backlog milestone whose description has the line `Release: business`. Backlog milestones without that line (the backlog's own tooling and documents) are not releases and follow "Milestones" above.

- **Feature issue.** Lists the work in every repository it touches as a checklist, one line per issue or PR: `- [ ] galax-io/<repo>#<N> → <repo milestone>`. A line is checked when that work is merged and the repository milestone it names has been released, so its tag exists.
- **Repository work.** Every issue and PR of a feature carries the version milestone of its own repository and writes `Part of galax-io/galaxio-sdlc-backlog#<feature>`. A repository ships its own version when its milestone is complete, as under "Release Process". `scripts/check-linkage.sh` skips the same-milestone rule for a link to a feature; the PR still needs its own milestone.
- **Every PR links a feature.** No PR of a product repository merges without `Part of galax-io/galaxio-sdlc-backlog#<feature>` (or a closing link to a feature); `scripts/check-linkage.sh --pr` fails it. A bot's PR (a bot author, or a `dependabot/` or `update/` branch) and the backlog's own PRs are exempt. The backlog is private, so the CI job reads it with `BACKLOG_READ_TOKEN`, a read-only token for that repository (Issues and Metadata) set as an organization secret; without it the gate fails and says it cannot read the backlog. A technical PR with no feature of its own may skip this check with the maintainer's agreement: a line `No feature: <why, and who agreed>` of its own in its description, at least ten characters long, which the gate prints in its log. A milestone gets no standing feature of its own any more; the ones that exist stay until their release.
- **Work enters through the backlog.** A bug, an audit finding or a request is not worked on until it belongs to a feature: grouped into one or given one. An issue from outside stays in its repository, which is public, and carries the label `status:needs-feature` until it is linked to a feature in the backlog.
- **Feature done.** A feature issue is closed only when every line of its checklist is checked.
- **Release.** When every feature of a business milestone is closed, close the milestone and publish a GitHub Release in `galax-io/galaxio-sdlc-backlog` that lists each feature with the repository versions that carry it. Name the release and its tag by the milestone's id, the title up to its first em dash, lowercased (`M1 — first run` → `m1`).
- **Published releases are not edited.** A revert after the release is a new feature in the next business milestone.
- **Never** close a business milestone with an open feature, release a feature whose repository version is not tagged, or leave a repository version out of the release text.


## Labels (ALWAYS)

One label scheme for every repository of the organization: `scripts/labels.json` in `galax-io/galaxio-sdlc-backlog` (`plans/label-scheme.md` there says why). A label says what the milestone and the feature link do not: the kind of work, its topic, how bad it is, where it stands.

- **Names.** Every label is `group:value`. Labels a tool owns (GitHub's `good first issue` and `help wanted`, Dependabot's, and those code reads, listed as `reserved`) are left alone.
- **Exactly one `type:*` on every open issue:** `bug`, `enhancement`, `docs`, `maintenance`, `question`; in the backlog `type:feature` (an issue of a business milestone) or `type:standing` (the standing feature of an older milestone). An issue without a type is not triaged.
- **At most one each:** `severity:*` (`critical`, `high`, `medium`, `low`: the impact, not the order of work), `status:*` (`needs-triage`, `needs-info`, `needs-feature`, `ready-for-agent`, `ready-for-human`, `blocked`), `tier:*`.
- **Any number:** `area:*` (topics shared by every repository), `module:*` (parts of one repository, declared in the scheme), `source:external`, `source:audit`.
- **Not labels.** The order of work is the milestone: no `priority:*`. The feature is the `Part of` link: no `feature:*`. A rejected or duplicate issue is closed with that reason and a comment: no `wontfix`, `invalid`, `duplicate`.
- **The engine's labels** `sdlc:*` live in the backlog: the maintainer sets `sdlc:run`; only the engine sets `sdlc:gate`, `sdlc:done` and `sdlc:failed`.
- **A new label is a change to the scheme**, a PR to `scripts/labels.json`, not a label made in one repository. `scripts/sync-labels.sh` applies the scheme; `--check` lists what breaks it.

## Task number (ALWAYS)

A task of the backlog has one number across the organization: `BCKLG-<N>`, where `<N>` is its issue number in `galax-io/galaxio-sdlc-backlog`. It is the only number a spec gets, and it names the task wherever `#N` alone would be read as an issue or PR of another repository.

- **Spec.** Its directory is `specs/BCKLG-<N>-<name>/`, `<N>` its main task. Its `spec.md`, `plan.md` and `tasks.md` carry the line `**Задачи**: BCKLG-<N>[, BCKLG-<M>…]` under the title, or `**Tasks**: …` in a repository whose files are English only, read alike: every task it carries, the main one first. A task has one spec: before writing one, find the spec whose tasks line names the task, check it against the task as its issue says now, and update it rather than write another. A spec directory from before the number keeps its name.
- **Branch.** A spec branch made by hand is `spec/BCKLG-<N>-<name>`; the engine's run is `BCKLG-<N>-<time>`, on the branch `sdlc/BCKLG-<N>-<time>`.
- **Commit.** A commit that does a task's work carries the trailer `Refs: BCKLG-<N>`; its subject stays a Conventional Commit.
- **PR.** Its body carries the line `Refs: BCKLG-<N>` beside `Part of galax-io/galaxio-sdlc-backlog#<N>`.
- **Checked.** `scripts/check-linkage.sh --pr` fails a PR of a feature without its number, a spec directory it adds that is not named by a task, and a spec, plan or tasks without the tasks line; `--specs` checks every spec of a checkout.

