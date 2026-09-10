#!/usr/bin/env bash

niriland_command_emit_migration_plan() {
  local state_root="$1"
  local index
  local migration_id
  local migration_file

  niriland_discover_migrations "$REPO_ROOT/migrations"
  for index in "${!NIRILAND_MIGRATION_IDS[@]}"; do
    migration_id="${NIRILAND_MIGRATION_IDS[$index]}"
    migration_file="${NIRILAND_MIGRATION_FILES[$index]}"
    niriland_migration_receipt_status \
      "$migration_id" "$migration_file" "$state_root"
    case "$NIRILAND_MIGRATION_STATUS" in
      complete)
        niriland_plan_emit NOOP "migration:$migration_id" "$NIRILAND_MIGRATION_DETAIL"
        ;;
      pending)
        niriland_plan_emit MIGRATE "migration:$migration_id" "$NIRILAND_MIGRATION_DETAIL"
        ;;
      legacy)
        niriland_plan_emit DEFER "migration:$migration_id" "$NIRILAND_MIGRATION_DETAIL"
        ;;
      changed|invalid)
        niriland_plan_emit BLOCKED "migration:$migration_id" "$NIRILAND_MIGRATION_DETAIL"
        ;;
      *)
        niriland_die "Unknown migration status: $NIRILAND_MIGRATION_STATUS"
        ;;
    esac
  done
}

niriland_command_plan() {
  local prune=false
  local package_set
  local state_root

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prune)
        prune=true
        ;;
      -h|--help)
        niriland_usage
        return 0
        ;;
      *)
        niriland_die "Unknown plan option: $1" || return 1
        ;;
    esac
    shift
  done

  niriland_command_resolve_machine
  state_root="$(niriland_state_root)"
  niriland_plan_reset

  printf 'Niriland plan\n'
  printf 'Profile: %s\n' "$NIRILAND_PROFILE"
  printf 'Prune: %s\n\n' "$prune"
  niriland_plan_emit SELECT "profile:$NIRILAND_PROFILE" "selected by machine config"
  for package_set in "${NIRILAND_PACKAGE_SETS[@]}"; do
    niriland_plan_emit DEFER "package-set:$package_set" "package reconciliation begins in Phase 2"
  done
  niriland_command_emit_migration_plan "$state_root"
  if [[ "$prune" == "true" ]]; then
    niriland_plan_emit DEFER "package-prune:untracked" "removal analysis begins in Phase 2"
  fi
  niriland_plan_summary
  printf 'No files, packages, services, or state were changed.\n'
}
