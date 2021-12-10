---
layout: post
title:  "Сетап макбука"
date:   2021-12-10
categories: macos
permalink: /macbook-setup
---

## Установка обновлений

Apple menu () > About This Mac > Software Update.

## Шифрование диска FileVault

- Security & privacy -> FileVault
- Click the lock to make changes
- Turn On FileVault

## Установка Homebrew

Способ №1. С чтением скрипта

```bash
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/install-brew.sh
less /tmp/install-brew.sh # Читаем
/bin/bash /tmp/install-brew.sh
rm /tmp/install-brew.sh
```

Способ №2. Одной строкой, как рекомендуется на официальном сайте [Homebrew](https://brew.sh/index_ru)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Отключение Google Analytics. [Зачем Homebrew аналитика](https://docs.brew.sh/Analytics#why)

```
brew analytics off
```

## Клавиатура

System Preferences ->  Keyboard

(Если есть Touch Bar) Выбрать `Touch Bar shows [F1, F2, etc. Keys]`

☑ `Use F1, F2, etc. keys as standard function keys`

**⚠️ Modifier Keys нужно настраивать для внешних клавиатур отдельно.**

Modifier Keys… -> Caps Lock Key: Control

Keyboard -> Shortcuts -> Spotlight

Убрать галки:

☐ show spotlight search

☐ show finder search window

Keyboard -> Text

Убрать галки:

☐ Correct spelling automatically

☐ Capitalise words automatically

☐ Add full stop with double-space

☐ (Если есть Touch Bar) Touch Bar typing suggestions

☐ Use smart quotes and dashes

Keyboard -> Shortcuts -> Input Sources

☐ Select the previous input source

☑ Select next source in Input menu **`⌘Space`**

В Menu Bar, иконка рядом с часами(настройки wifi, яркость, громкость): **Keyboard Brightness - 0**

## Battery

System Preferences -> Battery -> Power Adapter -> Turn display off after: 45m

☐ Enable Power Nap while plugged into a power adapter

## Lock gesture

System Preferences -> Desktop & Screen Saver -> Screen Saver -> Show screen saver after 30 minutes

System Preferences -> Desktop & Screen Saver -> Screen Saver -> Hot Corners... -> Start Screen Saver

System Preferences -> Security & Privacy -> General -> Require password **`[immediately]`** after sleep or screen saver begins

## App Store

Установить:

- Blackmagic Disk Speed Test 4+
- Monosnap - screenshot editor

## Finder

Добавить в боковую панель (Favourites):

- `~`
- `~/ghq/github.com/`
- `~/Pictures/Monosnap/`

## Alfred

alfred первый раз открывать через Launchpad (в нижнем меню)

Begin Setup... Нужно читать и настраивать

Features -> System

☑ Eject

☑ Eject All

Appearance -> Alfred macOS Dark

Appearance -> Options

☑ Hide hat on Alfred window

Appearance -> Options

☑ Hide menu bar icon

## Spectacle

Previous Display - удалить шорткат

Next Display `⌃⌥⌘↩`

Left Half `⌃⌥⌘←`

Right Half `⌃⌥⌘→`

Top Half `⌃⌥⌘↑`

Bottom Half `⌃⌥⌘↓`

В нижнем правом углу стрелочка > Run... > as a background application

## jetbrains-toolbox

```bash
mkdir "${HOME}/bin"
echo "${HOME}/bin" # Вывод этой команды скопировать
```

jetbrains-toolbox -> Settinmgs -> Shell scripts location: **вставить сюда**

Дописать в `~/.zshrc`

`export PATH="$PATH:${HOME}/bin"`

В idea установить плагины:

- Scala
- String Manipulation

Settings -> Tools -> Terminal -> Configure terminal keybindings -> Plugins -> Terminal -> Switch Focus To Editor 
убрать шорткат для `Escape` через контекстное меню

## iterm

[https://iterm2.com/documentation-shell-integration.html](https://iterm2.com/documentation-shell-integration.html)

Iterm2 -> Install Shell Integration

Prefs -> General -> Closing -> ☐ Confirm Quit iTerm2 (убрать галочку)

## Dock

```bash
dockutil --remove Messages
dockutil --remove Mail
dockutil --remove Maps
dockutil --remove Photos
dockutil --remove FaceTime
dockutil --remove Contacts
dockutil --remove TV
dockutil --remove Safari
dockutil --remove Notes
dockutil --remove Reminders
dockutil --remove Music
dockutil --remove Podcasts
dockutil --remove 'Terminal'
dockutil --add /Applications/Google\ Chrome.app  --after 'Launchpad'
dockutil --add /Applications/Firefox.app --after 'Google Chrome'
dockutil --add /Applications/iTerm.app --after 'Firefox'
```

System Preferences -> Dock & Menu Bar

☑ Automatically hide and show the Dock

## Авторизация

- Mail
- bitwarden
- chrome
- standard-notes

## always open with

- На файле с нужным расширением открыть контекстное меню
- Get Info
- Open with: выбрать приложение
- Change All...

Изменение применится ко всем файлам такого формата

Форматы, для которых следует изменить `open with` приложение:

- `.mp4 -> vlc`
