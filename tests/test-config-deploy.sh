#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT

preserve_home="$test_dir/preserve-home"
mkdir -p "$preserve_home"
printf 'local profile\n' > "$preserve_home/.profile"
HOME="$preserve_home" NIRILAND_CONFIG_DEPLOY_MODE=preserve \
  bash "$TEST_ROOT/installer/steps/20-deploy-configs" >/dev/null
[[ "$(<"$preserve_home/.profile")" == "local profile" ]] \
  || fail "preserve mode overwrote a root-level home config"
pass "preserve mode protects every existing home target"

overwrite_home="$test_dir/overwrite-home"
external_target="$test_dir/external-ghostty-config"
mkdir -p "$overwrite_home/.config/ghostty"
printf 'external sentinel\n' > "$external_target"
ln -s "$external_target" "$overwrite_home/.config/ghostty/config"
HOME="$overwrite_home" NIRILAND_CONFIG_DEPLOY_MODE=overwrite \
  bash "$TEST_ROOT/installer/steps/20-deploy-configs" >/dev/null

[[ ! -L "$overwrite_home/.config/ghostty/config" ]] \
  || fail "overwrite mode retained the destination symlink"
cmp -s \
  "$TEST_ROOT/configs/home/.config/ghostty/config" \
  "$overwrite_home/.config/ghostty/config" \
  || fail "overwrite mode did not deploy the tracked file"
[[ "$(<"$external_target")" == "external sentinel" ]] \
  || fail "overwrite mode wrote through the destination symlink"
pass "overwrite mode replaces symlinks without changing their targets"

printf '1..%d\n' "$TEST_COUNT"
