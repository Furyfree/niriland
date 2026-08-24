# Plan output contract

`niriland plan` is read-only. Every resource line has an action, a stable
resource ID, and a one-line explanation:

```text
  ACTION   resource-type:stable-name       explanation
```

Phase 1 actions are:

- `SELECT`: selected local profile;
- `DEFER`: known desired resource whose reconciler belongs to a later phase;
- `MIGRATE`: pending migration using the current migration contract;
- `NOOP`: resource already matches its recorded state;
- `BLOCKED`: invalid state that must be resolved before mutation;
- `REMOVE`: removal proposed only by `plan --prune` once Phase 2 implements it.

Future phases may emit `CREATE` and `UPDATE`. Resource IDs remain stable across
runs and use forms such as `profile:desktop`, `package-set:base`,
`migration:2026-08-23-example`, and `home:.config/niri/config.kdl`.

The summary is derived from emitted resource actions. Phase 1 plans explicitly
label package and legacy migration work as deferred and never create the state
directory.
