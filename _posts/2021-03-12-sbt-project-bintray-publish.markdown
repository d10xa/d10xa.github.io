---
layout: post
title:  "Публикация sbt проекта в bintray"
date:   2021-03-12
categories: scala
permalink: /sbt-project-bintray-publish
---

Как сделать автоматическую публикацию sbt проекта в bintray при создании git тега.

## Добавление git плагина (для вытаскивания версий из тега)

1) Добавляем sbt-git плагин в `project/plugins.sbt`

```sbt
addSbtPlugin("com.typesafe.sbt" % "sbt-git" % "latest.release")
```

2) Редактируем build.sbt

Включаем git плагин для чтения названия тега:

```sbt
enablePlugins(GitVersioning)
```

Имя и организация. Влияет на название пакета (`organization % name % version`)

```sbt
name := "my-project"
organization := "com.example"
```

Ссылка на github репозиторий будет добавлена к bintray пакету:

```sbt
bintrayVcsUrl := Some("https://github.com/username/repository.git")
```

Указывать лицензию - обязательно:

```sbt
licenses += ("MIT", url("https://opensource.org/licenses/MIT"))
// или
licenses += ("Apache-2.0", url("https://opensource.org/licenses/Apache-2.0"))
```

## Настройка CI / github workflows

1) Добавляем sbt-bintray плагин в `project/plugins.sbt`

```sbt
addSbtPlugin("org.foundweekends" % "sbt-bintray" % "latest.release")
```

2) Создаём файл `.github/workflows/publish.yml`:

```yaml
name: Bintray publish

on:
  release:
    types: [created]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
    - name: Cache
      uses: actions/cache@v1.0.0
      with:
        path: ~/.cache/coursier/v1
        key: ${{ runner.os }}-coursier_v1
    - name: Set up JDK
      uses: actions/setup-java@v1
      with:
        java-version: 1.11
    - name: Publish
      run: sbt publish
      env:
        BINTRAY_USER: ${{ secrets.BINTRAY_USER }}
        BINTRAY_PASS: ${{ secrets.BINTRAY_PASS }}
```

3) Достаём API Key из bintray

Edit Profile -> API Key -> Copy To Clipboard

4) Устанавливаем переменные `BINTRAY_USER`, `BINTRAY_PASS` для github workflows

На гитхабе Settings -> Secrets -> New Repository Secret

в переменную BINTRAY_PASS вставляем API Key
