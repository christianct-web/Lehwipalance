#!/usr/bin/env bash
# Move this deployment's database from the local Postgres container to Supabase.
#
# Safest form - paste Supabase's string exactly as shown, placeholder and all,
# and give the password as a second argument (it gets URL-encoded for you):
#
#   ./switch-to-supabase.sh \
#     'postgresql://postgres.REF:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres' \
#     'the-actual-password'
#
# One argument also works if the password is already correctly URL-encoded.
#
# Use the SESSION POOLER string (Project Settings > Database > Connection
# string > Session pooler, port 5432). The direct connection is IPv6-only and
# this VPS has IPv4. Single-quote the arguments: these contain characters the
# shell would otherwise interpret.
#
# This does NOT copy existing rows. It is for a database that holds nothing
# worth keeping. Check first, and stop if there is real data:
#   docker compose -f docker-compose.prod.yml --profile localdb exec -T db \
#     psql -U lehwi -d lehwi -c 'select count(*) from orders'
set -euo pipefail
cd "$(dirname "$0")"
C=(docker compose -f docker-compose.prod.yml)

[ $# -ge 1 ] && [ $# -le 2 ] || {
  echo "usage: $0 '<supabase connection string>' ['<password>']" >&2; exit 2; }
RAW="$1"
PW="${2-}"

# Normalise the URL the way the app needs it: psycopg driver, TLS required, and
# a password that survives being part of a URL.
URL=$(python3 - "$RAW" "$PW" <<'PY'
import sys, re
from urllib.parse import quote

raw, pw_arg = sys.argv[1].strip(), (sys.argv[2] if len(sys.argv) > 2 else "")

# Parse on the raw text, not with urlsplit: an un-encoded password may contain
# "@", "/", "#" or "?", any of which makes urlsplit read the wrong host and
# hand back a plausible-looking but wrong URL. The host is whatever follows the
# LAST "@", so the password may contain "@" safely.
m = re.match(
    r"^postgres(?:ql)?(?:\+\w+)?://"   # scheme
    r"(?P<user>[^:@/]+):"              # user
    r"(?P<pw>.*)"                      # password (greedy, up to the last @)
    r"@(?P<host>[^@:/?#]+)"            # host
    r"(?::(?P<port>\d+))?"             # port
    r"(?P<path>/[^?#]*)?"              # database
    r"(?:\?(?P<query>[^#]*))?$",       # query
    raw,
)
if not m:
    sys.exit("refusing: could not parse that connection string. Paste the Session\n"
             "pooler string from Supabase exactly as shown and pass the password\n"
             "as a second argument.")

pw = pw_arg or m.group("pw")
if not pw:
    sys.exit("refusing: no password given")
if re.search(r"\[.*\]|YOUR[-_]?(DB[-_]?)?PASSWORD", pw, re.I):
    sys.exit("refusing: that is still the placeholder, not a password. Pass the\n"
             "real password as the second argument.")

# Re-encode from the plaintext so every reserved character is safe in a URL.
# If the password came from the URL it may already be encoded; encoding it again
# would corrupt it, so only encode when it is clearly plaintext.
if pw_arg or not re.search(r"%[0-9A-Fa-f]{2}", pw):
    pw = quote(pw, safe="")

host, port = m.group("host"), m.group("port")
db = m.group("path") or "/postgres"
query = m.group("query") or ""
if "sslmode" not in query:
    query = (query + "&" if query else "") + "sslmode=require"

netloc = f"{quote(m.group('user'), safe='')}:{pw}@{host}" + (f":{port}" if port else "")
print(f"postgresql+psycopg://{netloc}{db}?{query}")
PY
)
redact() { sed -E 's|//([^:]+):[^@]*@|//\1:***@|'; }
echo "Target: $(echo "$URL" | redact)"

echo "==> checking this VPS can reach it"
docker run --rm -e U="$URL" python:3.12-slim bash -c \
  'pip install -q "psycopg[binary]" >/dev/null && python -c "
import os, psycopg
u = os.environ[\"U\"].replace(\"postgresql+psycopg://\", \"postgresql://\")
with psycopg.connect(u, connect_timeout=15) as c:
    print(\"   connected:\", c.execute(\"select version()\").fetchone()[0][:60])
"'

echo "==> applying migrations to Supabase"
"${C[@]}" run --rm -e DATABASE_URL="$URL" --entrypoint sh api -c 'alembic upgrade head && alembic check'

BAK=".env.bak-$(date -u +%Y%m%d-%H%M%S)"
cp .env "$BAK"
echo "==> rewriting .env (backup: $BAK)"
python3 - "$URL" <<'PY'
import sys, pathlib, re
url = sys.argv[1]
p = pathlib.Path(".env"); lines = p.read_text().splitlines(keepends=True)
out = []
for ln in lines:
    if ln.startswith("DATABASE_URL="):
        out.append(f"DATABASE_URL={url}\n")
    elif ln.startswith("LOCALDB_PASSWORD="):
        out.append("# LOCALDB_PASSWORD no longer used: the database is Supabase.\n")
    else:
        out.append(ln)
p.write_text("".join(out))
PY

echo "==> restarting without the local Postgres"
"${C[@]}" --profile localdb stop db >/dev/null 2>&1 || true
"${C[@]}" up -d --force-recreate api web

echo "==> verifying"
for i in $(seq 1 24); do
  sleep 5
  H=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://lehwi.187-77-18-154.sslip.io/api/health || true)
  echo "   t+$((i*5))s health=$H"
  [ "$H" = "200" ] && break
done
[ "${H:-}" = "200" ] || { echo "FAILED: API not healthy. Logs:"; "${C[@]}" logs --tail 40 api; \
  echo "Roll back: cp $BAK .env && ${C[*]} --profile localdb up -d"; exit 1; }

echo
echo "Done. Database is Supabase."
echo "  - The local Postgres container is stopped but its volume (lehwi_db-data) is kept."
echo "    Remove it when you are sure: docker volume rm lehwi_db-data"
echo "  - Drop '--profile localdb' from compose commands from now on."
echo "  - Supabase handles backups now: remove the backup.sh cron entry (crontab -e)."
echo "  - Roll back with: cp $BAK .env && ${C[*]} --profile localdb up -d"
