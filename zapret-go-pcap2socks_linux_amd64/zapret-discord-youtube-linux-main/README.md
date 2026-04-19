# Zapret DPI Bypass — Linux

Адаптация [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) для Linux.

Основан на:

- [zapret](https://github.com/bol-van/zapret) — DPI bypass инструмент (ядро и бинарники `nfqws`)
- [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) — готовые стратегии обхода от Flowseal
- Правки от [AikoXanako](https://github.com/AikoXanako) — оптимизация стратегий ALT11

## Возможности

- 19 стратегий обхода DPI (конвертированы из Windows версии)
- Game Filter для обхода блокировок в играх (Amazon/China серверы)
- Автоопределение firewall (nftables / iptables)
- Обновление IP-листов и hosts файла с GitHub
- Управление через интерактивное меню (`service.sh`)
- Интеграция с systemd (опционально)
- Утилиты для конвертации Windows стратегий в Linux формат

## Зависимости

### Обязательные

| Пакет                         | Зачем                        |
| ----------------------------- | ---------------------------- |
| `nftables` **или** `iptables` | Firewall правила для NFQUEUE |
| `curl` или `wget`             | Скачивание обновлений листов |

### Включены в комплект (bin/)

| Бинарник | Описание                                          |
| -------- | ------------------------------------------------- |
| `nfqws`  | Основной инструмент обхода DPI (из zapret v72.10) |
| `tpws`   | Transparent proxy (альтернатива nfqws)            |
| `ip2net` | Утилита конвертации IP                            |
| `mdig`   | DNS lookup утилита                                |

## Структура проекта

```
Linux/
├── bin/                  # Бинарники nfqws, tpws + fake TLS/QUIC файлы
├── lists/                # IP и host листы
│   ├── ipset-all.txt     # Список IP для обхода
│   ├── list-general.txt  # Домены (Discord, YouTube, Instagram и др.)
│   ├── list-google.txt   # Домены Google
│   ├── *-exclude.txt     # Исключения
│   └── *-user.txt        # Пользовательские списки (домены и исключения)
├── strategies/           # 19 стратегий обхода (.sh)
├── tools/                # Утилиты
│   ├── convert.sh        # Конвертер одной стратегии (input.txt → output.txt)
│   └── batch-convert.sh  # Пакетный конвертер .bat → .sh
├── utils/                # Флаги настроек (game_filter и др.)
├── config                # Конфигурация (стратегия, порты, и т.д.)
├── zapret.sh             # Основной скрипт запуска
├── service.sh            # Интерактивное меню управления
├── update-lists.sh       # Обновление листов с GitHub
└── zapret.service        # Systemd unit файл
```

## Быстрый старт

```bash
# 1. Клонировать
git clone <url> && cd zapret-linux

# 2. Запустить меню
sudo ./service.sh

# 3. Выбрать "1. Start Zapret" и нужную стратегию, по умолчанию 11
```

### Или вручную

```bash
# Быстрый запуск с конкретной стартегией
sudo ./zapret.sh start <название стратегии>

# Остановка
sudo ./zapret.sh stop

# Статус
./zapret.sh status
```

## Меню управления (service.sh)

```
┌─ SERVICE ─────────────────────┐
│  1.  Start Zapret             │
│  2.  Stop Zapret              │
│  3.  Restart Zapret           │
│  4.  Check Status             │
├─ SETTINGS ────────────────────┤
│  5.  Game Filter              │
│  6.  IPSet Filter             │
│  7.  Auto-Update Check        │
│  8.  Install Systemd Service  │
│  9.  Uninstall Systemd Service│
├─ UPDATES ─────────────────────┤
│  10. Update IPSet List        │
│  11. Update Hosts File        │
│  12. Update All Lists         │
│  13. Check for Software Updates│
├─ TOOLS ───────────────────────┤
│  14. Run Diagnostics          │
│  15. Run Connection Tests     │
└───────────────────────────────┘
```

## Утилиты (tools/)

### Конвертер стратегий Windows → Linux

Для конвертации одной стратегии:

```bash
cd tools/
# Вставить Windows стратегию в input.txt
./convert.sh
# Результат в output.txt
```

Для пакетной конвертации:

```bash
./batch-convert.sh /path/to/bat/files/ ../strategies/
```

## Пользовательские списки

Файлы с суффиксом `-user` предназначены для добавления собственных доменов и IP в стратегии:

- `lists/list-general-user.txt` — добавление доменов для обхода
- `lists/list-exclude-user.txt` — добавление доменов-исключений (не дурить)
- `lists/ipset-exclude-user.txt` — добавление IP-адресов/подсетей (исключения)

Эти файлы не затираются при обновлении официальных листов.

## Update Hosts File

Обновляет `/etc/hosts` записями для Telegram web, Instagram и других сервисов. Записи хранятся в изолированном блоке:

```
# BEGIN zapret
149.154.167.220 telegram.me
149.154.167.220 web.telegram.org
...
# END zapret
```

Удалить записи:

```bash
sudo sed -i '/# BEGIN zapret/,/# END zapret/d' /etc/hosts
```

## Systemd

```bash
# Установить сервис
sudo ./service.sh  # пункт 8

# Управление
sudo systemctl start zapret
sudo systemctl stop zapret
sudo systemctl enable zapret    # автозапуск
sudo systemctl status zapret
```

## Права доступа

`nfqws` запускается от root, но **сбрасывает привилегии** до пользователя `nobody` для безопасности. Это значит, что `nobody` должен иметь возможность **пройти** через все директории в пути до файлов zapret.

### Проблема: `Permission denied` при запуске из домашней директории

```
file_open_test: Permission denied
cannot access hostlist file '/home/user/zapret/lists/list-google.txt'
```

Даже если файлы имеют права `666` (`rw-rw-rw-`), пользователь `nobody` не сможет до них добраться, если **родительская директория** (например `/home/user/`) не имеет флага execute (`x`) для other.

Типичные права домашних директорий:
- `drwx------` (`700`) — **nobody не пройдёт** ❌
- `drwxr-xr-x` (`755`) — nobody пройдёт ✅

### Решение

**Вариант 1** — Перенести zapret в `/opt` (рекомендуется):

```bash
sudo mv zapret-discord-youtube-linux /opt/zapret
cd /opt/zapret
sudo ./service.sh
```

**Вариант 2** — Добавить execute для others на домашнюю директорию:

```bash
chmod o+x /home/username
```

> **Примечание:** `chmod o+x` даёт другим пользователям только право **проходить** через директорию, но **не читать** её содержимое. Для чтения содержимого нужен ещё `o+r`.

При запуске скрипт автоматически проверяет права на все родительские директории и подскажет, какие команды выполнить.

## Устранение проблем

**Zapret не запускается:**

```bash
sudo ./service.sh  # пункт 14 (Diagnostics)
```

**`Permission denied` / не может открыть hostlist:**

См. раздел [Права доступа](#права-доступа) выше.

**Нет доступа к сайту после запуска:**

- Попробуйте другую стратегию
- Обновите IPSet список (пункт 10)
- Проверьте VPN — может конфликтовать

**Выбор firewall бэкенда:**

По умолчанию скрипт автоматически определяет доступный бэкенд (nftables приоритетнее). Для ручного выбора добавьте в `config`:

```bash
FIREWALL_BACKEND="iptables"   # или "nftables"
```

**Права на файлы:**

```bash
sudo chown -R $(whoami) lists/ utils/
```
