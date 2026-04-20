# Rust Rewrite Plan

This document is the implementation plan for the planned Niriland rewrite after the current homelab bring-up work is done.

It exists to answer one practical question:

How should Niriland move from the current Bash-heavy installer and helper-script model to a Rust-first core without rewriting the whole repo blindly?

## Why Rewrite

The current Bash implementation works, but the hard parts are now above the comfort ceiling for shell:

- installer and updater control flow
- resumability and state tracking
- step metadata and dependency handling
- plan vs apply behavior
- drift between docs and runtime behavior
- targeted migrations and selective replays
- clearer validation and error reporting
- future TUI support

The rewrite is not about replacing shell because shell is bad. It is about moving the orchestration and data-modeling parts into a language that is better suited for them.

Rust is the chosen rewrite direction because learning Rust is also an explicit project goal. That means the rewrite should be structured to teach Rust well, not just to produce a binary as fast as possible.

## Design Rules

- Keep `bootstrap` in Bash.
- Keep tiny one-shot wrappers in Bash when they are mostly direct command wrappers.
- Move orchestration, planning, validation, and state tracking into Rust.
- Do not make async or concurrency a phase-one goal.
- Do not make the TUI the foundation.
- Build a stable non-TUI CLI first, then put optional TUI flows on top of the same core engine.
- Reduce scope before rewriting: move tracked user config ownership to `dotfiles` so Niriland owns less user-state deployment logic.

## Scope Split After Rewrite

The rewrite should make ownership boundaries sharper, not blur them.

### Niriland should own

- install and update orchestration
- package manifests and package install/update flows
- system-level setup and validation
- desktop/session integration that is part of the platform itself
- repo-hosted modular Niri fragments that are intentionally platform-owned
- helper tools that are truly platform operations
- launcher assets that remain Niriland-owned

### `dotfiles` should own

- tracked user config deployment
- theming and browser config that are really personal dotfiles concerns
- tracked user-config migrations
- user-facing config redesign work

### Bash should still own

- `bootstrap`
- extremely small wrappers where Rust would only add ceremony
- shell-native leaf actions that are still best expressed as direct command sequences

## Dependency On The `dotfiles` Move

The `dotfiles` integration work in [ROADMAP.md](ROADMAP.md) is not separate from the rewrite. It is one of the main ways to make the rewrite tractable.

The target state is:

- `dotfiles` becomes the source of truth for tracked user config
- Niriland stops owning broad `$HOME` config deployment through `20-deploy-configs`
- Niriland keeps platform-level assets such as launcher entries and system-facing integration
- update behavior becomes clearer because tracked user config refreshes and platform maintenance are no longer mixed together

Practical implication:

- do not start the full Rust cutover before the `dotfiles` ownership split is designed clearly enough that the Rust code is not forced to preserve the current oversized `configs/base` responsibility forever

## Rewrite Goals

### Phase-one goals

- model steps and actions explicitly
- run install and update flows from Rust
- support `plan` and `apply`
- improve failure reporting
- add resumability or at least explicit checkpointing
- support dry-run behavior where practical
- preserve current operational behavior while reducing shell glue

### Later goals

- guided TUI flows using `ratatui`
- safe parallel discovery and validation work
- richer machine/profile modeling
- stronger config and migration validation

### Non-goals for the first cut

- rewriting every shell leaf into Rust immediately
- introducing async everywhere
- parallelizing stateful install steps by default
- rebuilding the UI before the core engine exists

## Target Architecture

The rewrite should be a Rust workspace with clear layers.

### Suggested crates

- `niriland-core`
  - step model
  - action model
  - manifest loading
  - plan generation
  - state/checkpoint model
  - validation logic
  - common error types

- `niriland-cli`
  - normal command-line entrypoint
  - user-facing commands like `install`, `update`, `plan`, `doctor`, `migrate`, `sync-config`

- `niriland-tui`
  - optional `ratatui` frontend over the same core engine
  - never the only frontend

- optional `niriland-actions`
  - strongly typed Rust actions for the leaf operations that are worth porting out of shell later

### Suggested top-level commands

- `niriland install`
- `niriland update`
- `niriland plan install`
- `niriland plan update`
- `niriland doctor`
- `niriland migrate`
- `niriland sync-config`

## Migration Strategy

The migration should be incremental, not a flag day.

### Stage 0: Stabilize the current Bash behavior

Before the Rust cutover:

- fix known doc/runtime drift
- keep step responsibilities legible
- avoid adding more large Bash abstractions
- reduce future rewrite scope by advancing the `dotfiles` ownership split

### Stage 1: Introduce the Rust runner around existing shell steps

First Rust milestone:

- load current step definitions from Rust
- execute existing shell steps in order
- capture status, timing, and failures
- support explicit step selection
- support checkpoint or resume metadata

This stage keeps most leaf behavior unchanged while moving the control plane into Rust.

### Stage 2: Replace install/update orchestration

Once the runner is stable:

- replace `install` orchestration with Rust
- replace `niriland-update` orchestration with Rust
- keep Bash leaves where they are still clean and stable
- move shared shell-only helpers behind Rust command wrappers where needed

### Stage 3: Move selected high-value leaves into Rust

Only after the control plane is solid:

- port the most error-prone Bash steps into Rust
- prefer steps that benefit from stronger modeling and validation
- keep simple command wrappers in shell unless Rust clearly improves them

Likely early Rust-port candidates:

- config/deploy planning
- manifest parsing and package-source validation
- update-step selection and replay logic
- migration target selection and aliases
- health checks and doctor output

Likely late or optional Rust-port candidates:

- very shell-native one-shot setup helpers
- tiny wrappers that just invoke one external tool

## Concurrency Policy

Rust makes concurrency available. That does not mean Niriland should use it everywhere.

### Good early concurrency targets

- filesystem scans
- config discovery
- validation passes
- package/status inspection
- read-only environment checks

### Bad early concurrency targets

- stateful install steps that mutate the same machine state
- package installation ordering
- PAM edits
- system service changes
- anything that becomes harder to reason about after a failure

Rule:

- sequential by default for mutating operations
- concurrent only where the safety case is obvious

## TUI Policy

The current roadmap mentions a TUI installer flow. The rewrite changes the right implementation path.

The target is not:

- a Gum-first wrapper around the existing Bash scripts

The target is:

- a later `ratatui` frontend over the Rust core once the non-TUI CLI is stable

That means:

- build CLI-first
- keep business logic out of the TUI layer
- treat the TUI as a guided frontend, not as the engine

## Proposed Sequence

The rewrite should happen in this order:

1. Finish enough homelab work that Niriland becomes the active focus again.
2. Advance the `dotfiles` ownership split so Niriland no longer has to own broad user-config deployment forever.
3. Create the Rust workspace and a minimal CLI entrypoint.
4. Implement Rust step metadata, plan generation, and shell-step execution.
5. Replace install and update orchestration with Rust while still calling shell leaves.
6. Add checkpointing, doctor output, and targeted migration support.
7. Add `ratatui` only after the CLI and core engine feel stable.
8. Add carefully scoped concurrency only where it reduces wall-clock time without increasing state risk.
9. Port selected leaf actions from Bash to Rust only when the gain is real.

## Acceptance Criteria

The first rewrite phase is successful when:

- `bootstrap` still works as the entrypoint
- the main install and update flows are orchestrated by Rust
- the Rust CLI can produce a plan before mutating anything
- failed runs are easier to resume or at least easier to diagnose
- doc/runtime drift becomes less likely because step metadata is explicit
- the `dotfiles` split reduces the amount of user-config behavior Niriland itself owns
- no TUI is required for normal operation

## Risks To Avoid

- starting with a TUI and discovering the core model is wrong later
- overusing async because Rust makes it tempting
- rewriting every shell step before the Rust control plane proves itself
- delaying the `dotfiles` split and then baking current config sprawl into the Rust design
- treating Rust itself as the architecture instead of using it to express a better architecture
