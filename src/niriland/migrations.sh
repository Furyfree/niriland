#!/usr/bin/env bash

# shellcheck source=src/niriland/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Globals are outputs consumed by the command after this library is sourced.
# shellcheck disable=SC2034
declare -ga NIRILAND_MIGRATION_IDS=()
# shellcheck disable=SC2034
declare -ga NIRILAND_MIGRATION_FILES=()
# shellcheck disable=SC2034
declare -g NIRILAND_MIGRATION_STATUS=""
# shellcheck disable=SC2034
declare -g NIRILAND_MIGRATION_DETAIL=""

niriland_discover_migrations() {
  local migrations_dir="$1"
  local file_name
  local migration_id
  local -a file_names=()

  NIRILAND_MIGRATION_IDS=()
  NIRILAND_MIGRATION_FILES=()
  [[ -d "$migrations_dir" ]] || return 0

  mapfile -t file_names < <(
    find "$migrations_dir" -maxdepth 1 -type f -name '*.sh' -printf '%f\n' \
      | LC_ALL=C sort
  )

  for file_name in "${file_names[@]}"; do
    if [[ ! "$file_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}(-[a-z0-9][a-z0-9-]*)?\.sh$ ]]; then
      niriland_die "Invalid migration filename: $file_name" || return 1
    fi
    [[ -x "$migrations_dir/$file_name" ]] \
      || niriland_die "Migration is not executable: $file_name" \
      || return 1
    migration_id="${file_name%.sh}"
    NIRILAND_MIGRATION_IDS+=("$migration_id")
    NIRILAND_MIGRATION_FILES+=("$migrations_dir/$file_name")
  done
}

niriland_migration_source_hash() {
  sha256sum "$1" | awk '{print $1}'
}

niriland_migration_has_contract() {
  grep -Fxq '# niriland-migration-v1' "$1"
}

# Outputs are intentionally returned through sourced-library globals.
# shellcheck disable=SC2034
niriland_migration_receipt_status() {
  local migration_id="$1"
  local migration_file="$2"
  local state_root="$3"
  local receipt="$state_root/migrations/$migration_id.receipt"
  local line
  local key
  local value
  local receipt_id=""
  local receipt_hash=""
  local receipt_outcome=""
  local receipt_completed_at=""
  local seen_id=false
  local seen_hash=false
  local seen_outcome=false
  local seen_completed_at=false
  local expected_hash

  # Status and detail are return values read by the caller after this function.
  # shellcheck disable=SC2034
  NIRILAND_MIGRATION_STATUS=""
  # shellcheck disable=SC2034
  NIRILAND_MIGRATION_DETAIL=""

  if ! niriland_migration_has_contract "$migration_file"; then
    NIRILAND_MIGRATION_STATUS="legacy"
    NIRILAND_MIGRATION_DETAIL="migration needs conversion to the v1 contract"
    return 0
  fi

  if [[ ! -f "$receipt" ]]; then
    NIRILAND_MIGRATION_STATUS="pending"
    NIRILAND_MIGRATION_DETAIL="migration has no success receipt"
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" == *=* ]] || {
      NIRILAND_MIGRATION_STATUS="invalid"
      NIRILAND_MIGRATION_DETAIL="receipt contains a malformed line"
      return 0
    }
    key="${line%%=*}"
    value="${line#*=}"
    case "$key" in
      id)
        if [[ "$seen_id" == "true" ]]; then
          NIRILAND_MIGRATION_STATUS="invalid"
          NIRILAND_MIGRATION_DETAIL="receipt contains duplicate key: id"
          return 0
        fi
        seen_id=true
        receipt_id="$value"
        ;;
      source_sha256)
        if [[ "$seen_hash" == "true" ]]; then
          NIRILAND_MIGRATION_STATUS="invalid"
          NIRILAND_MIGRATION_DETAIL="receipt contains duplicate key: source_sha256"
          return 0
        fi
        seen_hash=true
        receipt_hash="$value"
        ;;
      outcome)
        if [[ "$seen_outcome" == "true" ]]; then
          NIRILAND_MIGRATION_STATUS="invalid"
          NIRILAND_MIGRATION_DETAIL="receipt contains duplicate key: outcome"
          return 0
        fi
        seen_outcome=true
        receipt_outcome="$value"
        ;;
      completed_at)
        if [[ "$seen_completed_at" == "true" ]]; then
          NIRILAND_MIGRATION_STATUS="invalid"
          NIRILAND_MIGRATION_DETAIL="receipt contains duplicate key: completed_at"
          return 0
        fi
        seen_completed_at=true
        receipt_completed_at="$value"
        ;;
      *)
        NIRILAND_MIGRATION_STATUS="invalid"
        NIRILAND_MIGRATION_DETAIL="receipt contains unknown key: $key"
        return 0
        ;;
    esac
  done <"$receipt"

  expected_hash="$(niriland_migration_source_hash "$migration_file")"
  if [[ "$seen_id" != "true" || "$seen_hash" != "true" \
    || "$seen_outcome" != "true" || "$seen_completed_at" != "true" ]]; then
    NIRILAND_MIGRATION_STATUS="invalid"
    NIRILAND_MIGRATION_DETAIL="receipt is missing required keys"
  elif [[ ! "$receipt_hash" =~ ^[[:xdigit:]]{64}$ ]]; then
    NIRILAND_MIGRATION_STATUS="invalid"
    NIRILAND_MIGRATION_DETAIL="receipt source hash is invalid"
  elif [[ -z "$receipt_completed_at" || "$receipt_completed_at" == *[[:space:]]* ]]; then
    NIRILAND_MIGRATION_STATUS="invalid"
    NIRILAND_MIGRATION_DETAIL="receipt completion time is invalid"
  elif [[ "$receipt_id" != "$migration_id" ]]; then
    NIRILAND_MIGRATION_STATUS="invalid"
    NIRILAND_MIGRATION_DETAIL="receipt ID does not match migration"
  elif [[ "$receipt_hash" != "$expected_hash" ]]; then
    NIRILAND_MIGRATION_STATUS="changed"
    NIRILAND_MIGRATION_DETAIL="completed migration source changed"
  elif [[ "$receipt_outcome" != "applied" && "$receipt_outcome" != "already-satisfied" ]]; then
    NIRILAND_MIGRATION_STATUS="invalid"
    NIRILAND_MIGRATION_DETAIL="receipt outcome is not successful"
  else
    NIRILAND_MIGRATION_STATUS="complete"
    NIRILAND_MIGRATION_DETAIL="success receipt matches source"
  fi
}

niriland_migration_status_summary() {
  local state_root="$1"
  local index
  local complete=0
  local pending=0
  local legacy=0
  local blocked=0

  for index in "${!NIRILAND_MIGRATION_IDS[@]}"; do
    niriland_migration_receipt_status \
      "${NIRILAND_MIGRATION_IDS[$index]}" \
      "${NIRILAND_MIGRATION_FILES[$index]}" \
      "$state_root"
    case "$NIRILAND_MIGRATION_STATUS" in
      complete)
        complete=$((complete + 1))
        ;;
      pending)
        pending=$((pending + 1))
        ;;
      legacy)
        legacy=$((legacy + 1))
        ;;
      changed|invalid)
        blocked=$((blocked + 1))
        ;;
      *)
        niriland_die "Unknown migration status: $NIRILAND_MIGRATION_STATUS" \
          || return 1
        ;;
    esac
  done

  printf 'complete=%d, pending=%d, legacy=%d, blocked=%d\n' \
    "$complete" "$pending" "$legacy" "$blocked"
}
