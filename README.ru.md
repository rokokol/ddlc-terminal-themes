<div align="center">

# ddlc-terminal-themes

**Цвета Doki Doki Literature Club для kitty и btop, светлые и тёмные** （´ω｀♡%）

![kitty](https://img.shields.io/badge/kitty-theme-72D0FA?style=flat)
![btop](https://img.shields.io/badge/btop-theme-76C332?style=flat)
![Nix](https://img.shields.io/badge/Nix-flake-7EBAE4?style=flat&logo=nixos&logoColor=white)
[![palette](https://img.shields.io/badge/colours-ddlc--palette-FF80C0?style=flat)](https://github.com/rokokol/ddlc-palette)
[![license](https://img.shields.io/badge/MIT-3DA639?style=flat)](LICENSE)
[![build](https://github.com/rokokol/ddlc-terminal-themes/actions/workflows/build.yml/badge.svg)](https://github.com/rokokol/ddlc-terminal-themes/actions/workflows/build.yml)

[English](README.md)

</div>

Две темы терминала, отрендеренные из base16-схем [ddlc-palette](https://github.com/rokokol/ddlc-palette), которая снимает каждый цвет с [ddlc.moe](https://ddlc.moe), а не подбирает его на глаз. Единственное, что здесь выбрано вкусом, — какой слот куда идёт

Приехало из моего райса, **[rokokol/huix](https://github.com/rokokol/huix)**

```sh
# ничего не собирать и не устанавливать, просто посмотреть
nix build github:rokokol/ddlc-terminal-themes && cat result/share/ddlc-terminal-themes/ddlc-kitty-dark.conf
```

## Содержание

- [Как выглядит](#как-выглядит)
- [Установка](#установка)
  - [Home Manager](#home-manager)
  - [Любой другой дистрибутив](#любой-другой-дистрибутив)
- [Куда идут слоты](#куда-идут-слоты)
- [Перегенерация](#перегенерация)
- [Проверки](#проверки)
- [Структура](#структура)
- [Лицензия](#лицензия)

## Как выглядит

![kitty с fastfetch и листингом каталога](docs/screenshot-kitty.png)

![btop, все четыре панели](docs/screenshot-btop.png)
> Обои просвечивают, потому что kitty запущен с `background_opacity 0.9` — своей прозрачности темы не задают, а btop просто наследует терминальную

## Установка

### Home Manager

```nix
{
  inputs.ddlc-terminal-themes.url = "github:rokokol/ddlc-terminal-themes";

  # в home-конфигурации
  imports = [ inputs.ddlc-terminal-themes.homeManagerModules.default ];

  ddlc.kitty.enable = true;
  ddlc.btop.enable = true;
}
```

По переключателю на приложение, потому что подключаются они по-разному, и ошибаются как раз в подключении:

| опция | | по умолчанию |
| --- | --- | --- |
| `kitty.enable` | цвета в `kitty.conf`, после твоих собственных настроек — для одного ключа kitty берёт последнее слово | `false` |
| `kitty.variant` | `light` или `dark` | `dark` |
| `btop.enable` | обе темы в `~/.config/btop/themes/` и одна из них в `btop.conf` | `false` |
| `btop.variant` | какая именно названа. Вторая всё равно кладётся — btop показывает этот каталог, так что она в одном нажатии в его же меню | `dark` |

**Без модуля.** `lib.kitty.{light,dark}` и `lib.btop.{light,dark}` — пути, так что положить их можно самому через `readFile` или `source =`; `packages.default` раскладывает те же четыре файла в `share/ddlc-terminal-themes/`

### Любой другой дистрибутив

```sh
git clone https://github.com/rokokol/ddlc-terminal-themes
cd ddlc-terminal-themes
./install.sh              # --kitty или --btop, если нужна одна из двух
```

Ничего не собирается: [`dist/`](dist) закоммичен, так что это копирование в `~/.config`. kitty получает оба варианта рядом с `kitty.conf`, где `include ddlc-kitty-dark.conf` уже резолвится; btop показывает тему под именем файла, поэтому по дороге отбрасывается сегмент с именем приложения и `ddlc-btop-dark.theme` кладётся как `ddlc-dark.theme`

## Куда идут слоты

kitty повторяет [tinted-kitty](https://github.com/tinted-theming/tinted-kitty) слот в слот с одним отступлением: тот кладёт выделение на `base03`, и `base05` на нём выходит 1.65:1, поэтому выделение несёт `base02`

Для btop base16-шаблона нет нигде, так что его раскладка — собственная:

| | |
| --- | --- |
| панели | `cpu_box` синяя, `mem_box` зелёная, `net_box` пурпурная, `proc_box` голубая — четыре акцента, чтобы взгляд попадал в нужную |
| нагрузка | градиенты температуры, процессора и процессов растут по тёплым акцентам палитры: зелёный, потом жёлтый, потом красный |
| счётчики | free, cached, available, used, download и upload шкалы не несут, поэтому каждый — один цвет с пустыми mid и end, как btop и записывает плоский счётчик |

> [!NOTE]
> Варианты берут разные акценты, потому что палитра поляризована: цвет, который читается на `ink`, на `paper` уже пастель. Какой ключ палитры заполняет какой слот в каждом из них — [в таблице](https://github.com/rokokol/ddlc-palette/blob/master/README.ru.md#как-тема) ddlc-palette

## Перегенерация

`generate.sh` читает два base16-yaml и пишет `dist/`. devShell кладёт их в окружение:

```sh
nix develop -c ./generate.sh
./generate.sh --light base16-ddlc-light.yaml --dark base16-ddlc-dark.yaml   # без Nix
```

Схемы приходят из ddlc-palette и больше ниоткуда — измеряет палитра, а этот репозиторий только раскладывает. Еженедельный workflow перерендеривает против HEAD палитры, а не против лока, и заводит pull request, когда они разошлись: цвет не может уехать наверху и молча оставить эту тему в старом виде

## Проверки

`nix flake check` доказывает, что `dist/` — это то, что `generate.sh` пишет сегодня, что каждое значение в нём хекс и таблица ANSI целая, что модуль подключает оба приложения (и не трогает ни одного, когда выключен), а два скрипта проходят shellcheck и shfmt

## Структура

```
generate.sh   раскладка: на входе слоты base16, на выходе два конфига на вариант
nix/          module.nix, module-test.nix
dist/         отрендеренные темы, закоммичены для тех, у кого нет Nix
install.sh    для систем без Nix
```

## Лицензия

MIT. Цвета — Team Salvato
