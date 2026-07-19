#!/usr/bin/env bash

set -euo pipefail
printf 'verify-versioned-consumer %s\n' "$*" >> "$QUALITY_GATE_TEST_LOG"
