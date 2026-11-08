#!/usr/bin/env bash
# Nightly dump of the Lehwi Palance database running on this VPS.
# Only needed while DATABASE_URL points at the local "db" container: once the
# database is Supabase, Supabase's own backups replace this and the cron entry
# should be removed.
set -euo pipefail
cd /home/keiraops/lehwipalance
DEST=/home/keiraops/backups/lehwipalance
mkdir -p "$DEST"
OUT="$DEST/lehwi-$(date -u +%F-%H%M).sql.gz"
docker compose -f docker-compose.prod.yml --profile localdb exec -T db \
  pg_dump -U lehwi lehwi | gzip > "$OUT"
# A dump that cannot be read back is not a backup.
gzip -t "$OUT"
# Keep two weeks.
find "$DEST" -name 'lehwi-*.sql.gz' -mtime +14 -delete
echo "$(date -u +%FT%TZ) ok $OUT ($(du -h "$OUT" | cut -f1))"
