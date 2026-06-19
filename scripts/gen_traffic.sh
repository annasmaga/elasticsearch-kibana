#!/usr/bin/env bash
# Генерирует трафик на Nginx, чтобы в access.log появились записи.
# Использование: ./scripts/gen_traffic.sh [URL] [COUNT]
set -euo pipefail
URL="${1:-http://localhost:8080}"
COUNT="${2:-50}"

echo "Отправляю $COUNT запросов на $URL ..."
for i in $(seq 1 "$COUNT"); do
  curl -s -o /dev/null -w "%{http_code}\n" "$URL/" >/dev/null
  curl -s -o /dev/null "$URL/health" || true
  curl -s -o /dev/null "$URL/nonexistent-$i" || true   # сгенерит 404
done
echo "Готово. Проверь access.log и индексы в Kibana."
