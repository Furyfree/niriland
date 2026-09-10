# Roadmap

Niriland is in maintenance mode, superseded by Nimbus. [`PLAN.md`](PLAN.md)
preserves the earlier rewrite scope; its unfinished phases and the residual
work below are deferred.

## Current status

Phase 1 is implemented locally and establishes the safe foundation:

- strict machine and profile parsing;
- purpose-based package manifest contracts;
- stable read-only plan output and state paths;
- an automatic migration contract without migration execution;
- sudo credential keepalive without passwords in environment variables;
- removal of accepted obsolete cleanup and setup paths.

Its static validation is complete, but it remains unapplied to live
configuration or package state. Configuration deployment, package ownership,
Noctalia cutover, pruning, and post-install system changes belong to later
phases in `PLAN.md`. Consolidating the foundation does not start Phase 2.

## Residual work

- Phase 2: canonical `configs/home` symlinks, `configs/system` copies, XDG Zsh
  completion, package source/ownership reconciliation, and prune planning.
- Phase 3: Niri plus Noctalia v5, Noctalia Greeter, tracked GUI settings, portal
  validation, and safe DMS removal.
- Phase 4: update migration execution, resumability, script consolidation,
  package pruning, and purpose-based developer/tooling manifests.
- Phase 5: reversible FDE/TPM and suspend-then-hibernate post-install flows;
  retain certificate and fingerprint setup after safety review.
- Phase 6: desktop entry/icon polish, Messenger icon correction, Zed/Typst PDF
  handling, documentation, and a final two-machine drift audit.

## Closed or moved roadmap input

- Vesktop screen sharing works locally; preserve and validate its portal state.
- Bluetooth works on both machines; no machine-specific workaround remains.
- Standard desktop entries and Noctalia supersede the DMS launcher-plugin idea.
- Multiplexing and TUI launch helpers move to Herdr.
- Zathura is acceptable as configured and needs no additional polish.
- Flutter, Helium, Helix, and local Ollama/OpenWebUI setup are retired.
- Fedora and Hyprland remain later platform considerations outside this rewrite.
