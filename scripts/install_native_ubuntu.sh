#!/usr/bin/env bash
###############################################################################
# Нативная установка Elastic Stack 7.17 на Ubuntu 22.04 (apt).
# Альтернатива docker-compose — для "чистого" сервера, как в задании.
#
# ТРЕБОВАНИЯ: ~3-4 GB свободного диска, ~2 GB свободной RAM, sudo.
# Запуск по шагам (не вслепую!): читай комментарии и выполняй блоками.
###############################################################################
set -euo pipefail

### 0. Репозиторий Elastic 7.x ###############################################
sudo apt-get update
sudo apt-get install -y apt-transport-https gnupg curl
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch \
  | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update

### 1. ELASTICSEARCH — Задание 1 #############################################
sudo apt-get install -y elasticsearch

# Случайное имя кластера
RANDOM_CLUSTER="anna-elk-$(openssl rand -hex 3)"
echo "cluster.name: ${RANDOM_CLUSTER}"        | sudo tee -a /etc/elasticsearch/elasticsearch.yml
echo "node.name: hw-node-1"                   | sudo tee -a /etc/elasticsearch/elasticsearch.yml
echo "network.host: 0.0.0.0"                  | sudo tee -a /etc/elasticsearch/elasticsearch.yml
echo "discovery.type: single-node"            | sudo tee -a /etc/elasticsearch/elasticsearch.yml
# Маленький heap под слабый сервер
sudo sed -i 's/^-Xms.*/-Xms512m/; s/^-Xmx.*/-Xmx512m/' /etc/elasticsearch/jvm.options 2>/dev/null || \
  printf -- "-Xms512m\n-Xmx512m\n" | sudo tee /etc/elasticsearch/jvm.options.d/heap.options

sudo systemctl daemon-reload
sudo systemctl enable --now elasticsearch
sleep 20
# СКРИНШОТ для Задания 1:
curl -X GET 'localhost:9200/_cluster/health?pretty'

### 2. KIBANA — Задание 2 ####################################################
sudo apt-get install -y kibana
echo 'server.host: "0.0.0.0"'                       | sudo tee -a /etc/kibana/kibana.yml
echo 'elasticsearch.hosts: ["http://localhost:9200"]' | sudo tee -a /etc/kibana/kibana.yml
sudo systemctl enable --now kibana
# Открой http://<ip>:5601/app/dev_tools#/console и выполни GET /_cluster/health?pretty

### 3. NGINX + LOGSTASH — Задание 3 ##########################################
sudo apt-get install -y nginx logstash
sudo systemctl enable --now nginx
# Сгенерь трафик:
for i in $(seq 1 50); do curl -s localhost/ >/dev/null; curl -s localhost/nope-$i >/dev/null; done

# Пайплайн Logstash (скопируй logstash/pipeline/nginx.conf в /etc/logstash/conf.d/)
sudo cp "$(dirname "$0")/../logstash/pipeline/nginx.conf" /etc/logstash/conf.d/nginx.conf
# Дай logstash доступ к логам nginx
sudo usermod -aG adm logstash
sudo systemctl enable --now logstash
# В Kibana создай data view "nginx-logstash-*" и смотри логи в Discover.

### 4. FILEBEAT — Задание 4 ##################################################
# Остановим доставку через Logstash:
sudo systemctl stop logstash
sudo apt-get install -y filebeat
sudo cp "$(dirname "$0")/../filebeat/filebeat.yml" /etc/filebeat/filebeat.yml
# (в filebeat.yml hosts должен указывать на localhost:9200, а kibana на localhost:5601)
sudo filebeat modules enable nginx || true
sudo systemctl enable --now filebeat
# В Kibana создай data view "nginx-filebeat-*" и смотри логи в Discover.

echo "=== ГОТОВО. Имя кластера: ${RANDOM_CLUSTER} ==="
