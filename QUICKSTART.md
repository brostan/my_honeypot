# 🚀 Быстрый старт Cowrie Honeypot

## За 5 минут

### Локальное тестирование (macOS/Linux)

```bash
# 1. Перейдите в директорию проекта
cd /path/to/Honeypot

# 2. Запустите Cowrie
cd cowrie
./cowrie-env/bin/cowrie start

# 3. Проверьте, что работает
ssh -p 2222 root@localhost
# Используйте любой пароль, например: root, 12345678, admin

# 4. Просмотрите логи
tail -f var/log/cowrie/cowrie.log
```

### Docker (самый простой способ)

```bash
# 1. Запустите контейнер
docker-compose -f docker-compose.simple.yml up -d

# 2. Проверьте статус
docker-compose -f docker-compose.simple.yml ps

# 3. Подключитесь к honeypot
ssh -p 2222 root@localhost

# 4. Просмотрите логи
docker-compose -f docker-compose.simple.yml logs -f cowrie
```

## Развертывание на сервере

### Автоматическое развертывание (Ubuntu/Debian)

```bash
# 1. Скопируйте проект на сервер
scp -r Honeypot user@your-server:/home/user/

# 2. Подключитесь к серверу
ssh user@your-server

# 3. Запустите скрипт установки
cd /home/user/Honeypot
chmod +x deploy.sh
./deploy.sh

# Скрипт автоматически:
# - Установит все зависимости
# - Создаст пользователя cowrie
# - Настроит и запустит honeypot
# - Создаст systemd service
```

### Ручная установка

```bash
# 1. Установите зависимости
sudo apt-get update
sudo apt-get install -y git python3-pip python3-venv \
    libssl-dev libffi-dev build-essential authbind

# 2. Создайте пользователя
sudo adduser --disabled-password cowrie
sudo su - cowrie

# 3. Клонируйте и настройте
git clone https://github.com/cowrie/cowrie
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -e .

# 4. Скопируйте конфигурацию
cp /path/to/your/cowrie.cfg etc/cowrie.cfg
cp /path/to/your/userdb.txt etc/userdb.txt

# 5. Запустите
./bin/cowrie start
```

## Первые шаги после установки

### 1. Проверьте, что honeypot работает

```bash
# Проверка SSH
ssh -p 2222 root@localhost
# Попробуйте: root/root, admin/admin, root/12345678

# Проверка Telnet
telnet localhost 2223
```

### 2. Настройте перенаправление портов (опционально)

Для прослушивания стандартных портов 22 и 23:

```bash
# Вариант 1: iptables
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223

# Вариант 2: authbind (уже настроено скриптом deploy.sh)
# Просто измените порты в etc/cowrie.cfg на 22 и 23
```

### 3. Начните мониторинг

```bash
# Просмотр логов в реальном времени
./scripts/monitor.sh

# Или просто tail
tail -f cowrie/var/log/cowrie/cowrie.json
```

### 4. Проверьте первые результаты

```bash
# Анализ статистики
./scripts/analyze.sh

# Или вручную
jq . cowrie/var/log/cowrie/cowrie.json | less
```

## Полезные команды

### Управление Cowrie

```bash
# Запуск
./cowrie/bin/cowrie start
# или (systemd)
sudo systemctl start cowrie

# Остановка
./cowrie/bin/cowrie stop
# или
sudo systemctl stop cowrie

# Перезапуск
./cowrie/bin/cowrie restart
# или
sudo systemctl restart cowrie

# Статус
./cowrie/bin/cowrie status
# или
sudo systemctl status cowrie
```

### Просмотр логов

```bash
# Текстовые логи
tail -f cowrie/var/log/cowrie/cowrie.log

# JSON логи (структурированные)
tail -f cowrie/var/log/cowrie/cowrie.json

# С форматированием
tail -f cowrie/var/log/cowrie/cowrie.json | jq .

# Systemd логи
sudo journalctl -u cowrie -f
```

### Воспроизведение сессий

```bash
# Список всех сессий
ls -lh cowrie/var/lib/cowrie/tty/

# Воспроизвести конкретную сессию
./cowrie/bin/playlog cowrie/var/lib/cowrie/tty/20231210-120000-abcd1234.log
```

### Просмотр загруженных файлов

```bash
# Список файлов
ls -lh cowrie/var/lib/cowrie/downloads/

# Проверка файла (безопасно!)
file cowrie/var/lib/cowrie/downloads/abc123def456
strings cowrie/var/lib/cowrie/downloads/abc123def456

# Сканирование антивирусом
clamscan cowrie/var/lib/cowrie/downloads/
```

## Docker команды

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Логи
docker-compose logs -f cowrie

# Статус
docker-compose ps

# Вход в контейнер
docker exec -it cowrie-honeypot /bin/bash
```

## Анализ данных

### Топ атакующих IP

```bash
jq -r 'select(.eventid=="cowrie.session.connect") | .src_ip' \
  cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | sort -rn | head -10
```

### Топ паролей

```bash
jq -r 'select(.eventid=="cowrie.login.success") | .password' \
  cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | sort -rn | head -10
```

### Топ команд

```bash
jq -r 'select(.eventid=="cowrie.command.input") | .input' \
  cowrie/var/log/cowrie/cowrie.json | sort | uniq -c | sort -rn | head -10
```

### Загруженные файлы

```bash
jq -r 'select(.eventid=="cowrie.session.file_download") | "\(.timestamp) \(.url)"' \
  cowrie/var/log/cowrie/cowrie.json
```

## Доступ к веб-интерфейсам (полный стек)

После запуска `docker-compose up -d`:

| Сервис | URL | Учетные данные |
|--------|-----|----------------|
| Kibana | http://localhost:5601 | - |
| Grafana | http://localhost:3000 | admin / admin |
| Elasticsearch | http://localhost:9200 | - |
| Portainer | https://localhost:9443 | Создайте при первом входе |

## Устранение проблем

### Порт уже используется

```bash
# Найдите процесс
sudo lsof -i :2222

# Остановите SSH (если нужно)
sudo systemctl stop ssh
```

### Cowrie не запускается

```bash
# Проверьте логи
tail -n 50 cowrie/var/log/cowrie/cowrie.log

# Проверьте права
ls -la cowrie/var/

# Проверьте конфигурацию
cat cowrie/etc/cowrie.cfg
```

### Docker проблемы

```bash
# Пересоздать контейнеры
docker-compose down -v
docker-compose up -d

# Посмотреть логи
docker-compose logs
```

## Следующие шаги

1. **Прочитайте документацию**
   - [README.md](README.md) - полное описание проекта
   - [MONITORING.md](MONITORING.md) - детальный мониторинг и анализ
   - [SECURITY.md](SECURITY.md) - важные рекомендации по безопасности

2. **Настройте мониторинг**
   - Запустите полный стек с ELK: `docker-compose up -d`
   - Настройте дашборды в Kibana и Grafana
   - Настройте алерты на важные события

3. **Автоматизируйте**
   - Настройте cron для регулярных отчетов
   - Настройте автоматический бэкап
   - Интегрируйте с вашей SIEM системой

4. **Изучайте атаки**
   - Анализируйте логи ежедневно
   - Воспроизводите интересные сессии
   - Исследуйте загруженные файлы (безопасно!)
   - Делитесь находками с сообществом

## Полезные ссылки

- [Официальная документация Cowrie](https://docs.cowrie.org/)
- [GitHub Cowrie](https://github.com/cowrie/cowrie)
- [Cowrie Slack](https://www.cowrie.org/slack/)
- [jq Tutorial](https://stedolan.github.io/jq/tutorial/)

## Получить помощь

Если что-то не работает:

1. Проверьте логи: `tail -f cowrie/var/log/cowrie/cowrie.log`
2. Проверьте статус: `systemctl status cowrie` или `docker-compose ps`
3. Посмотрите [SECURITY.md](SECURITY.md) и [MONITORING.md](MONITORING.md)
4. Задайте вопрос в [Cowrie Slack](https://www.cowrie.org/slack/)

---

**Готово! Ваш honeypot запущен и готов ловить атакующих! 🎣**

