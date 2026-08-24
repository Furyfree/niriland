#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"
# shellcheck source=src/niriland/migrations.sh
source "$TEST_ROOT/src/niriland/migrations.sh"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/migrations" "$test_dir/state/migrations"

printf '%s\n' '#!/usr/bin/env bash' '# niriland-migration-v1' \
  >"$test_dir/migrations/2026-08-23-example.sh"
printf '%s\n' '#!/usr/bin/env bash' \
  >"$test_dir/migrations/2026-08-22-legacy.sh"
chmod +x "$test_dir/migrations/2026-08-22-legacy.sh" \
  "$test_dir/migrations/2026-08-23-example.sh"

niriland_discover_migrations "$test_dir/migrations"
[[ "${NIRILAND_MIGRATION_IDS[*]}" == \
  "2026-08-22-legacy 2026-08-23-example" ]] \
  || fail "migrations were not discovered in lexical order"
pass "migration discovery has stable lexical ordering"

printf '%s\n' '#!/usr/bin/env bash' \
  >"$test_dir/migrations/2026-08-24-not-executable.sh"
assert_command_fails "non-executable migrations must fail discovery" \
  niriland_discover_migrations "$test_dir/migrations"
rm -f -- "$test_dir/migrations/2026-08-24-not-executable.sh"
pass "migration discovery rejects non-executable scripts"

niriland_migration_receipt_status \
  2026-08-22-legacy "$test_dir/migrations/2026-08-22-legacy.sh" "$test_dir/state"
[[ "$NIRILAND_MIGRATION_STATUS" == "legacy" ]] \
  || fail "legacy migration was not classified"
pass "legacy migration is deferred safely"

niriland_migration_receipt_status \
  2026-08-23-example "$test_dir/migrations/2026-08-23-example.sh" "$test_dir/state"
[[ "$NIRILAND_MIGRATION_STATUS" == "pending" ]] \
  || fail "contract migration without receipt was not pending"
pass "contract migration without receipt is pending"

migration_summary="$(niriland_migration_status_summary "$test_dir/state")"
[[ "$migration_summary" == 'complete=0, pending=1, legacy=1, blocked=0' ]] \
  || fail "pending migration summary was incorrect: $migration_summary"
pass "migration summary reports pending and legacy states"

source_hash="$(niriland_migration_source_hash "$test_dir/migrations/2026-08-23-example.sh")"
printf '%s\n' \
  'id=2026-08-23-example' \
  "source_sha256=$source_hash" \
  'outcome=already-satisfied' \
  'completed_at=2026-08-23T12:00:00+02:00' \
  >"$test_dir/state/migrations/2026-08-23-example.receipt"
niriland_migration_receipt_status \
  2026-08-23-example "$test_dir/migrations/2026-08-23-example.sh" "$test_dir/state"
[[ "$NIRILAND_MIGRATION_STATUS" == "complete" ]] \
  || fail "matching receipt was not complete"
pass "matching migration receipt is complete"

migration_summary="$(niriland_migration_status_summary "$test_dir/state")"
[[ "$migration_summary" == 'complete=1, pending=0, legacy=1, blocked=0' ]] \
  || fail "complete migration summary was incorrect: $migration_summary"
pass "migration summary reports completed receipts"

printf '%s\n' \
  'id=2026-08-23-example' \
  'id=2026-08-23-example' \
  "source_sha256=$source_hash" \
  'outcome=applied' \
  'completed_at=2026-08-23T12:00:00+02:00' \
  >"$test_dir/state/migrations/2026-08-23-example.receipt"
niriland_migration_receipt_status \
  2026-08-23-example "$test_dir/migrations/2026-08-23-example.sh" "$test_dir/state"
[[ "$NIRILAND_MIGRATION_STATUS" == "invalid" ]] \
  || fail "duplicate receipt keys were accepted"
pass "migration receipts reject duplicate keys"

printf '%s\n' \
  'id=2026-08-23-example' \
  "source_sha256=$source_hash" \
  'outcome=already-satisfied' \
  'completed_at=2026-08-23T12:00:00+02:00' \
  >"$test_dir/state/migrations/2026-08-23-example.receipt"
printf '%s\n' '# changed after completion' \
  >>"$test_dir/migrations/2026-08-23-example.sh"
niriland_migration_receipt_status \
  2026-08-23-example "$test_dir/migrations/2026-08-23-example.sh" "$test_dir/state"
[[ "$NIRILAND_MIGRATION_STATUS" == "changed" ]] \
  || fail "changed completed migration was not blocked"
pass "completed migration source is immutable"

migration_summary="$(niriland_migration_status_summary "$test_dir/state")"
[[ "$migration_summary" == 'complete=0, pending=0, legacy=1, blocked=1' ]] \
  || fail "blocked migration summary was incorrect: $migration_summary"
pass "migration summary reports changed receipts as blocked"

printf '1..%d\n' "$TEST_COUNT"
