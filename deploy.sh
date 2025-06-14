#!/bin/bash
set -e

cd "$(dirname "$0")/docker/dev" || exit 1
exec /usr/local/bin/docker compose up --build -d