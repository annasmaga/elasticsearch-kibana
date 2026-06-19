#!/usr/bin/env bash
# Полный снос ELK-стека и освобождение диска.
# Запусти ПОСЛЕ того, как снимешь все 4 скриншота.
set -euo pipefail
cd "$(dirname "$0")/.."

# Останавливаем и удаляем все контейнеры + тома (esdata, nginxlog)
docker compose --profile logstash --profile filebeat down -v

# Удаляем образы стека, чтобы вернуть ~2.5 GB диска
docker rmi docker.elastic.co/elasticsearch/elasticsearch:7.17.22 \
           docker.elastic.co/kibana/kibana:7.17.22 \
           docker.elastic.co/logstash/logstash:7.17.22 \
           docker.elastic.co/beats/filebeat:7.17.22 \
           nginx:1.25 2>/dev/null || true

echo "=== Готово. Диск: ==="
df -h / | tail -1
