#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

demonolith split refactor -y --monorepo --overwrite --engine tofu 
