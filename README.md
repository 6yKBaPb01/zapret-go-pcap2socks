zapret-go-pcap2socks - проект, который состоит из проектов, как [zapret-discord-youtube от Flowseal](https://github.com/Flowseal/zapret-discord-youtube) и [go-pcap2socks от DaniilSokolyuk](https://github.com/DaniilSokolyuk/go-pcap2socks) (для андроидов/линуксных/яблочников: [zapret от bol-van](https://github.com/bol-van/zapret)).
Для каждой ОС эта сборка пойдёт (на masOS - запуск как в Linux).
Для андроидов(Нужен Termux и root права!):
```
pkg update
pkg install root-repo
pkg install git golang libpcap tsu

go install github.com/DaniilSokolyuk/go-pcap2socks@latest

sudo $HOME/go/bin/go-pcap2socks
```
или
```
tsu -c "$HOME/go/bin/go-pcap2socks"
```
Далее включите VPN любой или скачайте [zapret от bol-van](https://github.com/bol-van/zapret)
Для установки пропишите(кто установил git, оно установит все версии):
```
git clone "https://github.com/6yKBaPb01/zapret-go-pcap2socks"
```
Или скачайте это всё в разделе Release.
Документация по программам:
[go-pcap2socks](https://github.com/DaniilSokolyuk/go-pcap2socks) - программа, специально созданна, для раздачи VPN соединения на все абсолютно устройства. То PS4, то Nintendo Switch, неважно.
zapret можно даже не объяснять, это Bypass(VPN) программа, для обхода блокировок.
Если что-то у вас не будет работать, пишите в разделе Issues или в дс 6yKBaPbRL
