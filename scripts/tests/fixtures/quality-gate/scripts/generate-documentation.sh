#!/usr/bin/env bash

set -euo pipefail
printf 'generate-documentation %s\n' "$*" >> "$QUALITY_GATE_TEST_LOG"
