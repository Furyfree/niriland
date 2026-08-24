# Installer

This directory contains Niriland's active fresh-install flow:

- `install` orchestrates the numbered steps;
- `lib/` contains installer-only shared code;
- `steps/` contains the lifecycle-ordered install actions.

The installer remains available until `niriland apply` provides the complete
replacement. It is mutating and may install packages, overwrite configuration,
enable services, and request sudo. Do not run it as a validation command.

Globally callable commands belong in `../bin/`, not in this directory.
