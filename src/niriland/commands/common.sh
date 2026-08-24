#!/usr/bin/env bash

niriland_command_resolve_machine() {
  local config_file="${NIRILAND_MACHINE_CONFIG:-$REPO_ROOT/machine.local.conf}"

  niriland_resolve_machine "$REPO_ROOT" "$config_file"
}
