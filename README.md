# 🚀 zapret-go-pcap2socks

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows-blue?logo=windows" alt="Windows" />
  <img src="https://img.shields.io/badge/language-Go-00ADD8?logo=go" alt="Go" />
  <img src="https://img.shields.io/badge/language-Lua-00ADD8?logo=lua" alt="Lua" />
  <img src="https://img.shields.io/badge/language-Python-00ADD8?logo=Python" alt="Python" />
  <img src="https://img.shields.io/badge/license-GPL%203.0%20%2F%20MIT-green" alt="License" />
</p>

> [!WARNING]
> Антивирус может ложно определять **zapret-discord-youtube** как вредоносное ПО.  
> Это известная проблема, можете исключить его или выключить антивирус на время установки. Подробнее: [zapret-win-bundle readme](https://github.com/bol-van/zapret-win-bundle/blob/master/readme.md).

> [!CAUTION]
> Я веду [Telegram-канал](https://t.me/podbal6ykbapb) и [Youtube-канал](https://www.youtube.com/@6yKBaPb-q9s). Если увидите что не с моих распростроняется этот форк в другой ссылке или не там, не ведитесь! ЭТО СКАМ!!!
> Если вы решите сделать обзор на него, то оставляйте ссылку оригинальную! 
> Пример других ссылок или не там:
> 1) публикация в телеграм каналах(или в других площадках)
> 2) другой автор в GitHub (но если это форк, пропускаем). Если были какие то попытки подменить мой ник - точно скам
> 3) ссылка совсем другая. Такая же ситуация была и с оригинальным zapret-discord-youtube.

## 📦 Описание

**zapret-go-pcap2socks** — форк, объединяющий два мощных проекта:

- [zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) от **Flowseal**
- [go-pcap2socks](https://github.com/DaniilSokolyuk/go-pcap2socks) от **DaniilSokolyuk**

Идея проста: `zapret` обходит DPI-блокировки, а `go-pcap2socks` раздаёт получившееся соединение на **все устройства в локальной сети** — будь то ПК, PS4, Nintendo Switch или что угодно ещё.

Принцип работы:

<img width="978" height="700" alt="работа" src="https://github.com/user-attachments/assets/afe83b23-a3c2-4988-a300-17560169c726" />

---

## Небольшое но..

На консолях нужно выставить MTU вручную (из документации go-pcap2socks), а на телефонах если просит префикс, ставьте 16

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

## Плюсы форка:

- Обход блокировок
- ПК ваш личный роутер, спокойно можно настроить

## Минусы форка:

- Пропадает из радара роутера 
- Нужно чтобы устройства были на одной сети было (т.е. подключены к ПК) если есть что-то по локальной сети.
- Пинг ВПН взлетает до небес. 
## 💾 Установка через Git

```bash
git clone "https://github.com/6yKBaPb01/zapret-go-pcap2socks-windows"
```

## ❓ Q/A(вопрос/ответ):
**Можно использовать вместо zapret, любой VPN?**
- Да можно, это даже круто

**С какой целью ты делал этот форк?**
- Хотел восстановить доступ Roblox на PS4. хах

**Что делать если go-pcap2socks перестал запускаться?**
- Проверьте config.json (в папке utils), по возможности удалите этот конфиг, программа сама восстановит конфиг. Если вы модифицировали go-pcap2socks, попробуйте переустановить и проверьте где вы накосячили.

## 💬 Поддержка:
Если что‑то не работает — создайте обращение в разделе Issues или свяжитесь со мной в Discord: 6yKBaPb01 или 6yKBaPbRL. 

<picture> <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=6yKBaPb01/zapret-go-pcap2socks&type=date&theme=dark&legend=top-left" /> <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=6yKBaPb01/zapret-go-pcap2socks&type=date&legend=top-left" /> <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=6yKBaPb01/zapret-go-pcap2socks&type=date&legend=top-left" /> </picture>
