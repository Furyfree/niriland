# Migration contract

Migrations are one-time transitions that cannot be represented safely as
ordinary convergent resources. The new update workflow will discover executable
files named `YYYY-MM-DD-slug.sh` in lexical order.

New managed migrations must:

- contain the exact marker `# niriland-migration-v1`;
- support `describe`, `check`, `plan`, and `apply` subcommands;
- keep `describe`, `check`, and `plan` read-only;
- make `apply` idempotent and stop when preconditions are ambiguous;
- print the concrete recovery procedure during `plan`;
- never invoke another migration directly.

Successful runs receive a file at
`~/.local/state/niriland/migrations/<id>.receipt`:

```ini
id=2026-08-23-example
source_sha256=<sha256 of the migration script>
outcome=applied
completed_at=2026-08-23T12:00:00+02:00
```

`outcome=already-satisfied` is also successful. Once a receipt exists, changing
the migration source is an error; add a new migration instead.

The retained scripts from before this contract are reported as legacy and are
not executed by the Phase 1 command. They must gain a read-only satisfaction
check or be retired before automatic update migrations are enabled.
