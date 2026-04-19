# Zapret Strategy Converter

Утилиты для конвертации Windows стратегий zapret (winws.exe) в Linux формат (nfqws).

## Файлы

```
tools/
├── convert.sh       # Конвертер одной стратегии (input.txt → output.txt)
├── batch-convert.sh # Пакетный конвертер всех .bat → .sh
├── input.txt        # Сюда вставлять Windows стратегию
├── output.txt       # Результат конвертации
└── README.md
```

## convert.sh — конвертер одной стратегии

1. Вставьте Windows стратегию в `input.txt`:

   ```
   winws.exe --wf-tcp=80,443 --filter-tcp=443 --dpi-desync=fake --new --filter-udp=443 --dpi-desync=fake
   ```

2. Запустите:

   ```bash
   ./convert.sh
   ```

3. Результат в `output.txt`

### Опции

```bash
./convert.sh --help         # Справка
./convert.sh --qnum 300     # NFQUEUE 300 вместо 200
```

## batch-convert.sh — пакетный конвертер

Конвертирует все `.bat` файлы из директории в `.sh` стратегии:

```bash
./batch-convert.sh /path/to/windows/strategies/ ../strategies/
```

Формат имени: `general (ALT11).bat` → `general-alt11.sh`

## Что конвертируется

| Windows        | Linux                                         |
| -------------- | --------------------------------------------- |
| `winws.exe`    | удаляется (nfqws запускается через zapret.sh) |
| `--wf-tcp=...` | удаляется (firewall настраивается отдельно)   |
| `--wf-udp=...` | удаляется                                     |
| `%BIN%`        | `$BIN_DIR/` (задаётся в zapret.sh)            |
| `%LISTS%`      | `$LISTS_DIR/` (задаётся в zapret.sh)          |
| `%GameFilter%` | удаляется                                     |

> **Важно:** Стратегии НЕ определяют `$BIN_DIR` и `$LISTS_DIR` — эти переменные предоставляются `zapret.sh` при загрузке стратегии через `source`.
