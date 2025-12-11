# 📊 Мониторинг и Анализ Cowrie Honeypot

## Содержание

1. [Обзор](#обзор)
2. [Логирование](#логирование)
3. [Анализ в реальном времени](#анализ-в-реальном-времени)
4. [Визуализация данных](#визуализация-данных)
5. [Алерты и уведомления](#алерты-и-уведомления)
6. [Автоматизация анализа](#автоматизация-анализа)

## Обзор

Cowrie генерирует детальные логи всех действий атакующих. Эффективный мониторинг позволяет:
- Выявлять новые техники атак
- Собирать threat intelligence
- Обнаруживать вредоносное ПО
- Анализировать поведение атакующих

## Логирование

### Типы логов

#### 1. JSON Logs (`cowrie.json`)
Структурированные логи всех событий:

```json
{
  "eventid": "cowrie.login.success",
  "timestamp": "2023-12-10T12:00:00.000000Z",
  "src_ip": "192.168.1.100",
  "username": "root",
  "password": "12345678",
  "session": "a1b2c3d4"
}
```

#### 2. Text Logs (`cowrie.log`)
Человекочитаемые логи для отладки:

```
2023-12-10T12:00:00+0000 [cowrie.ssh.factory.CowrieSSHFactory] New connection: 192.168.1.100:54321
2023-12-10T12:00:05+0000 [SSHService b'ssh-userauth' on HoneyPotSSHTransport] login attempt [root/12345678] succeeded
```

#### 3. TTY Logs
Записи терминальных сессий для replay:

```bash
./cowrie/bin/playlog cowrie/var/lib/cowrie/tty/20231210-120000-a1b2c3d4.log
```

### Структура событий

| Event ID | Описание |
|----------|----------|
| `cowrie.session.connect` | Новое подключение |
| `cowrie.login.success` | Успешная аутентификация |
| `cowrie.login.failed` | Неудачная попытка входа |
| `cowrie.command.input` | Выполненная команда |
| `cowrie.session.file_download` | Загрузка файла |
| `cowrie.session.file_upload` | Выгрузка файла |
| `cowrie.session.closed` | Закрытие сессии |

## Анализ в реальном времени

### Использование скриптов

#### Мониторинг в реальном времени

```bash
./scripts/monitor.sh
```

Показывает события по мере их возникновения с цветовой кодировкой:
- 🟢 Зеленый - новые подключения
- 🟡 Желтый - успешные входы
- 🔴 Красный - неудачные попытки/отключения
- 🔵 Синий - выполненные команды
- 🔷 Голубой - загрузки файлов

#### Анализ статистики

```bash
./scripts/analyze.sh
```

Генерирует отчет с:
- Общей статистикой сессий
- Топ IP-адресов атакующих
- Топ используемых учетных данных
- Топ выполненных команд
- Списком загруженных файлов

### Ручной анализ с jq

#### Топ IP-адресов

```bash
jq -r 'select(.eventid=="cowrie.session.connect") | .src_ip' \
  cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | sort -rn | head -20
```

#### Успешные входы за последний час

```bash
jq -r 'select(.eventid=="cowrie.login.success" and 
  (.timestamp | fromdateiso8601) > (now - 3600)) | 
  "\(.timestamp) \(.username):\(.password) from \(.src_ip)"' \
  cowrie/var/log/cowrie/cowrie.json
```

#### Все команды от конкретного IP

```bash
jq -r 'select(.eventid=="cowrie.command.input" and .src_ip=="192.168.1.100") | 
  "\(.timestamp) \(.input)"' \
  cowrie/var/log/cowrie/cowrie.json
```

#### Поиск попыток эксплуатации уязвимостей

```bash
jq -r 'select(.eventid=="cowrie.command.input" and 
  (.input | test("curl|wget|/bin/sh|bash -i|nc |ncat "))) | 
  "\(.timestamp) \(.src_ip) \(.input)"' \
  cowrie/var/log/cowrie/cowrie.json
```

## Визуализация данных

### Kibana

#### Настройка Index Pattern

1. Откройте Kibana: http://localhost:5601
2. Management → Stack Management → Index Patterns
3. Create Index Pattern: `cowrie-*`
4. Select timestamp field: `@timestamp`

#### Полезные визуализации

**1. Временная шкала событий**
- Visualization type: Line chart
- X-axis: Date Histogram on @timestamp
- Y-axis: Count
- Split series: eventid

**2. География атак**
- Visualization type: Maps
- Layer: Choropleth
- Field: geoip.country_name
- Metric: Count

**3. Топ атакующих IP**
- Visualization type: Data table
- Rows: src_ip (Top 20)
- Metrics: Count

**4. Облако используемых паролей**
- Visualization type: Tag cloud
- Tags: password
- Size: Count

#### Пример запроса в Kibana

```
eventid:"cowrie.login.success" AND username:"root"
```

### Grafana

#### Добавление Elasticsearch Data Source

1. Configuration → Data Sources → Add data source
2. Select: Elasticsearch
3. URL: http://elasticsearch:9200
4. Index name: `cowrie-*`
5. Time field: `@timestamp`

#### Примеры панелей

**1. Счетчик событий**

```sql
{
  "query": "eventid:cowrie.session.connect",
  "alias": "Connections"
}
```

**2. График входов по времени**

```sql
{
  "query": "eventid:cowrie.login.success OR eventid:cowrie.login.failed",
  "alias": "Login Attempts"
}
```

**3. Топ команд (Table)**

```sql
{
  "query": "eventid:cowrie.command.input",
  "metrics": [
    {
      "type": "count",
      "field": "input.keyword"
    }
  ]
}
```

## Алерты и уведомления

### ElastAlert (рекомендуется)

#### Установка

```bash
pip install elastalert2
```

#### Конфигурация алертов

**Алерт на загрузку файлов** (`rules/file_download.yaml`):

```yaml
name: File Download Alert
type: any
index: cowrie-*
filter:
  - term:
      eventid: "cowrie.session.file_download"
alert:
  - email
email:
  - security@example.com
alert_subject: "Honeypot: File Downloaded"
alert_text: |
  File downloaded from honeypot!
  URL: {url}
  Source IP: {src_ip}
  Timestamp: {timestamp}
```

**Алерт на подозрительные команды**:

```yaml
name: Suspicious Commands
type: any
index: cowrie-*
filter:
  - term:
      eventid: "cowrie.command.input"
  - query:
      query_string:
        query: 'input:(*curl* OR *wget* OR */dev/tcp* OR *bash -i*)'
alert:
  - email
  - slack
```

### Telegram Bot для алертов

```python
#!/usr/bin/env python3
import json
import requests
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

TELEGRAM_BOT_TOKEN = "YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID = "YOUR_CHAT_ID"

class CowrieHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith('cowrie.json'):
            with open(event.src_path, 'r') as f:
                lines = f.readlines()
                if lines:
                    event_data = json.loads(lines[-1])
                    if event_data.get('eventid') == 'cowrie.session.file_download':
                        send_telegram_alert(event_data)

def send_telegram_alert(data):
    message = f"🚨 File Download Alert!\n\n"
    message += f"URL: {data.get('url')}\n"
    message += f"Source IP: {data.get('src_ip')}\n"
    message += f"Time: {data.get('timestamp')}"
    
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    requests.post(url, data={'chat_id': TELEGRAM_CHAT_ID, 'text': message})

if __name__ == "__main__":
    observer = Observer()
    observer.schedule(CowrieHandler(), path='cowrie/var/log/cowrie/', recursive=False)
    observer.start()
    observer.join()
```

## Автоматизация анализа

### Cron задачи

#### Ежедневный отчет

```bash
# /etc/cron.daily/cowrie-report
#!/bin/bash
cd /path/to/Honeypot
./scripts/analyze.sh > /tmp/cowrie-report.txt
mail -s "Daily Cowrie Report" admin@example.com < /tmp/cowrie-report.txt
```

#### Автоматический бэкап

```bash
# /etc/cron.weekly/cowrie-backup
#!/bin/bash
cd /path/to/Honeypot
./scripts/backup.sh
```

### Интеграция с SIEM

#### Отправка в Splunk

```ini
# etc/cowrie.cfg
[output_splunk]
enabled = true
host = splunk.example.com
port = 8088
token = YOUR_HEC_TOKEN
index = cowrie
sourcetype = cowrie_json
```

#### Отправка в Graylog

```ini
[output_graylog]
enabled = true
host = graylog.example.com
port = 12201
```

### Threat Intelligence

#### Проверка IP через AbuseIPDB

```bash
#!/bin/bash
API_KEY="YOUR_API_KEY"
IP="$1"

curl -G https://api.abuseipdb.com/api/v2/check \
  --data-urlencode "ipAddress=$IP" \
  -H "Key: $API_KEY" \
  -H "Accept: application/json"
```

#### Автоматическая проверка всех IP

```bash
jq -r 'select(.eventid=="cowrie.session.connect") | .src_ip' \
  cowrie/var/log/cowrie/cowrie.json | sort -u | \
  while read ip; do
    echo "Checking $ip..."
    ./check_ip.sh "$ip"
    sleep 1
  done
```

## Метрики производительности

### Мониторинг ресурсов

```bash
# CPU и память Cowrie
ps aux | grep cowrie

# Размер логов
du -sh cowrie/var/log/cowrie/

# Количество загруженных файлов
ls -1 cowrie/var/lib/cowrie/downloads/ | wc -l

# Активные сессии
lsof -i :2222 | wc -l
```

### Prometheus метрики

Cowrie может экспортировать метрики для Prometheus:

```ini
# etc/cowrie.cfg
[output_prometheus]
enabled = true
port = 9000
```

Пример запросов Prometheus:

```promql
# Количество подключений в секунду
rate(cowrie_sessions_total[5m])

# Успешные входы
cowrie_login_success_total

# Выполненные команды
rate(cowrie_commands_total[5m])
```

## Best Practices

1. **Регулярно проверяйте логи** - хотя бы раз в день
2. **Настройте алерты** на критичные события (загрузка файлов, подозрительные команды)
3. **Делайте бэкапы** логов и загруженных файлов
4. **Анализируйте тренды** - отслеживайте изменения в тактиках атакующих
5. **Делитесь данными** с сообществом (anonymized)
6. **Обновляйте базы threat intelligence** на основе собранных данных
7. **Документируйте интересные находки** для будущего анализа

## Полезные ресурсы

- [Cowrie Documentation](https://docs.cowrie.org/)
- [ELK Stack Documentation](https://www.elastic.co/guide/)
- [Grafana Documentation](https://grafana.com/docs/)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Awesome Threat Intelligence](https://github.com/hslatman/awesome-threat-intelligence)

---

**Следующие шаги**: См. [SECURITY.md](SECURITY.md) для рекомендаций по безопасности

