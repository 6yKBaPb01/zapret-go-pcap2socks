# 🚀 zapret-go-pcap2socks

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows-blue?logo=windows" alt="Windows" />
  <img src="https://img.shields.io/badge/language-Go-00ADD8?logo=go" alt="Go" />
  <img src="https://img.shields.io/badge/license-GPL%203.0%20%2F%20MIT-green" alt="License" />
</p>

> ⚠️ **Внимание**  
> Антивирус может ложно определять компоненты **zapret** как вредоносное ПО.  
> Это известная особенность, подробнее: [zapret-win-bundle readme](https://github.com/bol-van/zapret-win-bundle/blob/master/readme.md).


## 📦 Описание

**zapret-go-pcap2socks** — форк, объединяющий два мощных проекта:

- [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) от **Flowseal**
- [go-pcap2socks](https://github.com/DaniilSokolyuk/go-pcap2socks) от **DaniilSokolyuk**

Идея проста: `zapret` обходит DPI-блокировки, а `go-pcap2socks` раздаёт получившееся соединение на **все устройства в локальной сети** — будь то ПК, PS4, Nintendo Switch или что угодно ещё.

---

## 📖 Документация

### 🔹 go-pcap2socks
Специализированная программа для раздачи VPN‑подключения на абсолютно любые устройства.  
Работает как прозрачный SOCKS‑туннель поверх захваченного трафика.

**Подробнее:** [github.com/DaniilSokolyuk/go-pcap2socks](https://github.com/DaniilSokolyuk/go-pcap2socks)

### 🔹 zapret-discord-youtube
Взят оттуда: [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube). DPI‑дурилка (инструмент обхода блокировок). Мгновенно восстанавливает доступ к YouTube, Discord и другим сервисам, которые подвергаются глубокой инспекции пакетов.

### 🔹 blockcheck
Этот инструмент был взят из [zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle). Он помогает найти лучшую стратегию для вас. Если что, вы можете опубликовать через Pull Request или в Issues

### 🔹 AS Parser
Скрипт был взят из [IPSets-For-Bypass-in-Russia](https://github.com/V3nilla/IPSets-For-Bypass-in-Russia). Позволяет найти новые IP адреса с помощью ASN (автономные системы IP).

### 🔹 TG WS Proxy
Приложение было взято: [TG WS Proxy](https://github.com/Flowseal/tg-ws-proxy). Создаёт локальный прокси для обхода блокировки Telegram.

---

## ⚖️ Лицензии

Проект основан на двух исходных работах, каждая со своей лицензией:

- **go-pcap2socks** – [GPL-3.0 License](https://github.com/DaniilSokolyuk/go-pcap2socks?tab=GPL-3.0-1-ov-file#readme)  
- **zapret-discord-youtube** – [Other License](https://github.com/Flowseal/zapret-discord-youtube?tab=License-1-ov-file#readme)
- **TG WS Proxy** - [MIT License](https://github.com/Flowseal/tg-ws-proxy?tab=MIT-1-ov-file)

Пожалуйста, соблюдайте условия обеих лицензий при использовании и распространении.

---

## 💾 Установка через Git

```bash
git clone "https://github.com/6yKBaPb01/zapret-go-pcap2socks-windows"
```

## 💬 Поддержка:
Если что‑то не работает — создайте обращение в разделе Issues или свяжитесь со мной в Discord: 6yKBaPb01 или 6yKBaPbRL. 

<picture> <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=6yKBaPb01/zapret-go-pcap2socks&type=date&theme=dark&legend=top-left" /> <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=6yKBaPb01/zapret-go-pcap2socks&type=date&legend=top-left" /> <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=6yKBaPb01/zapret-go-pcap2socks&type=date&legend=top-left" /> </picture>
