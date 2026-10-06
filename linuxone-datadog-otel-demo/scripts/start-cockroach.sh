#!/usr/bin/env bash
# Start a single-node CockroachDB with memory sized to this VM (Part 5.2).
# Override the sizing by exporting CACHE_PCT and SQL_PCT before running.
set -euo pipefail

sudo mkdir -p /var/lib/cockroach && sudo chown "$USER" /var/lib/cockroach

MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if [ -z "${CACHE_PCT:-}" ] || [ -z "${SQL_PCT:-}" ]; then
  if [ "$MEM_MB" -lt 8192 ]; then
    CACHE_PCT=10; SQL_PCT=15    # under 8 GB: leave room for the Collector and load generator
  else
    CACHE_PCT=25; SQL_PCT=25    # 8 GB or more: Cockroach Labs' production recommendation
  fi
fi
CACHE_MB=$(( MEM_MB * CACHE_PCT / 100 ))
SQL_MB=$(( MEM_MB * SQL_PCT / 100 ))
echo "VM memory: ${MEM_MB} MiB -> cache ${CACHE_MB} MiB, SQL memory ${SQL_MB} MiB"

cockroach start-single-node --insecure \
  --store=/var/lib/cockroach \
  --listen-addr=localhost:26257 --http-addr=localhost:8080 \
  --cache=${CACHE_MB}MiB --max-sql-memory=${SQL_MB}MiB \
  --background

cockroach sql --insecure --host=localhost:26257 -e "select version();"
curl -s localhost:8080/_status/vars | head -3   # Prometheus-format lines
