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

https://brew.sh

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Отключение Google Analytics. [Зачем Homebrew аналитика](https://docs.brew.sh/Analytics#why)

```bash
brew analytics off
```

## yadm

```bash
brew install yadm
yadm clone https://github.com/d10xa/dotfiles.git
yadm bootstrap
```

## Клавиатура

System Preferences ->  Keyboard

(Если есть Touch Bar) Выбрать `Touch Bar shows [F1, F2, etc. Keys]`

<div class="checkbox-selected"></div> `Use F1, F2, etc. keys as standard function keys`

**⚠️ Modifier Keys нужно настраивать для внешних клавиатур отдельно.**

Modifier Keys… -> Caps Lock Key: Control

Keyboard -> Shortcuts -> Spotlight

Убрать галки:

<div class="checkbox-empty"></div> show spotlight search

<div class="checkbox-empty"></div> show finder search window

Keyboard -> Text (На более свежих macOs: Text Input -> Edit...)

Убрать галки:

<div class="checkbox-empty"></div> Correct spelling automatically

<div class="checkbox-empty"></div> Capitalise words automatically

<div class="checkbox-empty"></div> Add full stop with double-space

<div class="checkbox-empty"></div> (Если есть Touch Bar) Touch Bar typing suggestions

<div class="checkbox-empty"></div> Use smart quotes and dashes

Keyboard -> Shortcuts -> Input Sources

<div class="checkbox-empty"></div> Select the previous input source

<div class="checkbox-selected"></div> Select next source in Input menu **`⌘Space`**

## Trackpad

<div class="checkbox-selected"></div> Silent clicking

Point & Click -> Tracking speed -> 6/10

## Turn display off

Старый macOs:

System Preferences -> Battery -> Power Adapter -> Turn display off after: 30m

Новый macOs:

System Preferences -> Lock Screen -> Turn display off on power adapter when inactive: for 30 minutes

Старый macOs:

System Preferences -> Battery -> Power Adapter ->
<div class="checkbox-empty"></div> Enable Power Nap while plugged into a power adapter

Новый macOs:

System Preferences -> Battery -> Options... -> Wake for network access -> Never

## Убрать громкий звук при старте

System Preferences -> Sound -> <div class="checkbox-empty"></div> Play sound on startup

## Lock gesture

Старый macOs:

System Preferences -> Desktop & Screen Saver -> Screen Saver -> Show screen saver after 30 minutes

System Preferences -> Desktop & Screen Saver -> Screen Saver -> Hot Corners... -> Start Screen Saver

System Preferences -> Security & Privacy -> General -> Require password **`[immediately]`** after sleep or screen saver begins

Новый macOs:

System Preferences -> Screen Saver -> Start Screen Saver when inactive -> For 30 minutes

System Preferences -> Desktop & Dock -> Hot Corners... -> Start Screen Saver

System Preferences -> Require password after screen saver begins or display is turned off -> **`[Immediately]`**

## App Store

Установить:

- Blackmagic Disk Speed Test 4+

## Finder

Добавить в боковую панель (Favourites):

- `~`
- `~/ghq/`
- `~/ghq/github.com/`


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

Prefs -> General -> Closing

<div class="checkbox-empty"></div> Confirm Quit iTerm2

## Dock

```bash
dockutil --remove Messages
dockutil --remove Mail
dockutil --remove Maps
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
# Optionally
dockutil --remove Photos
```

System Preferences -> Dock & Menu Bar

<div class="checkbox-selected"></div> Automatically hide and show the Dock

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
