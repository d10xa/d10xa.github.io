---
layout: post
title:  "Несколько аккаунтов github на одном компьютере"
date:   2023-02-11
categories: git
permalink: /multiple-github-accounts
---

Статья про настройку ssh ключей для работы с разных GitHub аккаунтов на одном компьютере (macOs)
Подобных статей в интеренте и без меня достаточно.
Основная часть везде одинакова, но есть особенности моего исползования.

## Дисклеймер

Аккаунт с именем account2 существует на гитхабе, это не мой. Я его просто для примера использую.

## macOs

Некоторые части этой статьи специфичны для macOs. Например, параметр `--apple-use-keychain` в ssh-add.

## Отключить автоматические name & email при коммитах

Не рекомендую использовать глобальные переменные git при работе с несколькими аккаунтами. Очень легко ошибиться и закоммитить с неправильным именем/мэйлом.
Удалить глобальные переменные и запретить генерировать следующими командами:

```bash
git config --global --unset-all user.name
git config --global --unset-all user.email
git config --global user.useConfigOnly true
```

- [user.useConfigOnly](https://git-scm.com/docs/git-config#Documentation/git-config.txt-useruseConfigOnly) - отключает автоматическую генерацию name, email для git пользователя
- [--unset-all](https://git-scm.com/docs/git-config#Documentation/git-config.txt---unset-all) удаляет параметры из глобальной конфигурации

## Создать отдельный аккаунт на гитхабе

На один gmail можно создать больше одного аккаунта. Например, для мэйла example@gmail.com можно указать example+account2@gmail.com.
Письмо с подтверждением придёт на основной ящик.

## Создание ssh ключа

```
cd ~/.ssh
ssh-keygen -t ed25519 -C "example+account2@gmail.com" -f account2
```

-f путь, по которому будет сохранен приватный ключ. Публичный будет создан рядом с расширением `.pub`

**ПАРОЛЬ СТАВИМ СЛОЖНЫЙ. НЕ ОСТАВЛЯЕМ КЛЮЧ БЕЗ ПАРОЛЯ.** Пароль сохранится в keychain, его не придётся вводить каждый раз заново.

## Редактируем конфиг ssh

Добавляем аккаунт в конфиг

<p class="filename">~/.ssh/config</p>

```
Host github-account2
    HostName github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519_account2
```

## Добавляем ПУБЛИЧНЫЙ ssh ключ на GitHub

Копируем в буфер обмена публичный ключ:

```
pbcopy < ~/.ssh/id_ed25519_account2.pub
```

Добавляем ключ на GitHub:

Settings > [SSH and GPG keys](https://github.com/settings/keys) > New SSH Key

После добавления, публичный ключ окажется в открытом доступе по ссылке:

`https://github.com/{username}.keys`


## ssh-add

Добавляем ключ в keychain, вводим пароль. Это нужно, что бы не вводить пароль каждый раз.

```
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_account2
```

## git clone

Дойдя до этой части статьи, уже можно клонировать репозиторий, используя ssh ключ.

```
git clone git@github-account2:account2/test.git
```

Хост в урле соответствует параметру `Host` из ssh конфига (про него выше).

## git clone https -> ssh

Для удобства, можно настроить автоматическое переписывание https урла на ssh

<p class="filename">~/.gitconfig</p>

```
[url "ssh://git@github.com/account2"]
   insteadOf = https://github.com/account2
```

С такой настройкой `https://github.com/account2/test.git` перепишется на `git@github-account2:account2/test.git`

Можно будет копировать https ссылки в ui гитхаба, а клонироваться они будут по ssh. Это избавит от ручного написания урла с кастомным хостом.

## Устанавливаем user.name и user.email на все проекты пользователя

Воспользуемся фичей гита [Conditional includes](https://git-scm.com/docs/git-config#_conditional_includes), появившейся в git 2.13

Добавляем:

<p class="filename">~/.gitconfig</p>

```
[includeIf "gitdir:~/ghq/github.com/account2/"]
    path = ~/.gitconfig-account2
```

<p class="filename">~/.gitconfig-account2</p>

```
[user]
    name = Your Username
    email = YourEmail@example.com
```

Для каждого нового пользователя - свой файлик с конфигом и строка includeIf в `.gitconfig`

## ghq

[ghq](https://github.com/x-motemen/ghq) - Утилита для клонирования репозиториев в правильное место на диске

После настройки переписывания урла из https в ssh - работает автоматически.

Почему работает:

```
ghq get https://github.com/account2/test.git
```

1. Утилита берет url, который ей передали и на основе него формирует локальный путь к репозиторию
2. Запускает процесс git clone с https урлом
3. git смотрит в файл .gitconfig видит там замену https на ssh
4. репозиторий клонируется с помощью ssh, но в локальную директорию, как будто это https репозиторий
