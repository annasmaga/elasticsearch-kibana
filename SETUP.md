# SETUP — как поднять стек ELK 7.17

Два способа. Выбери один.

## Вариант A. Docker Compose (рекомендуется, безопасно)

Требования: Docker + Docker Compose, ~3 GB RAM, ~3 GB диска.

```bash
cp .env.example .env
# (опц.) поменять CLUSTER_NAME: openssl rand -hex 4

# Задания 1-2: Elasticsearch + Kibana + Nginx
docker compose up -d elasticsearch kibana nginx
curl -X GET 'localhost:9200/_cluster/health?pretty'      # Задание 1
# Kibana: http://localhost:5601/app/dev_tools#/console    # Задание 2

# Задание 3: Logstash
docker compose --profile logstash up -d
bash scripts/gen_traffic.sh
# Kibana Data View: nginx-logstash-*

# Задание 4: переключение на Filebeat
docker compose stop logstash
docker compose --profile filebeat up -d
bash scripts/gen_traffic.sh
# Kibana Data View: nginx-filebeat-*
```

Полная остановка и очистка:
```bash
docker compose --profile logstash --profile filebeat down -v
```

> ⚠️ На Linux Elasticsearch требует `vm.max_map_count >= 262144`:
> ```bash
> sudo sysctl -w vm.max_map_count=262144
> ```

## Вариант B. Нативная установка на сервере (Ubuntu 22.04)

Ближе к формулировке задания («на сервере»). Требует ~3-4 GB свободного диска
и ~2 GB RAM. Скрипт — `scripts/install_native_ubuntu.sh`.

**Не запускай вслепую** — выполняй блоками, читая комментарии. Скрипт:
1. подключает apt-репозиторий Elastic 7.x;
2. ставит Elasticsearch, задаёт случайный `cluster.name`, heap 512m;
3. ставит Kibana (`server.host: 0.0.0.0`);
4. ставит Nginx + Logstash, копирует pipeline;
5. ставит Filebeat и переключает доставку с Logstash на Filebeat.

## Проверка ресурсов перед стартом

```bash
df -h /            # диск: нужно >= 3 GB свободно
free -h            # RAM: нужно >= 2 GB доступно
```
