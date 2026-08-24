#!/usr/bin/env bash

niriland_command_status() {
  local state_root
  local package_sets
  local migration_states

  niriland_command_resolve_machine
  state_root="$(niriland_state_root)"
  package_sets="$(IFS=,; printf '%s' "${NIRILAND_PACKAGE_SETS[*]}")"
  niriland_discover_migrations "$REPO_ROOT/migrations"
  migration_states="$(niriland_migration_status_summary "$state_root")"

  printf 'Profile: %s\n' "$NIRILAND_PROFILE"
  printf 'Profile file: %s\n' "$NIRILAND_PROFILE_FILE"
  printf 'Package sets: %s\n' "$package_sets"
  printf 'State root: %s%s\n' "$state_root" \
    "$([[ -d "$state_root" ]] && printf ' (present)' || printf ' (not created)')"
  printf 'Discovered migrations: %d\n' "${#NIRILAND_MIGRATION_IDS[@]}"
  printf 'Migration states: %s\n' "$migration_states"
}
