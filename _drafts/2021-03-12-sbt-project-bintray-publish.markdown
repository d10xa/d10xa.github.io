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

```scala
addSbtPlugin("com.typesafe.sbt" % "sbt-git" % "latest.release")
```

2) Редактируем build.sbt

Включаем git плагин для чтения названия тега:

```scala
enablePlugins(GitVersioning)
```

Удаляем явное указание версии:

```scala
version := "0.1.2" // Удалить
```

## Конфигурация для bintray

1) Добавляем sbt-bintray плагин в `project/plugins.sbt`

```
!!! WARNING: !!!

https://github.com/sbt/sbt-bintray
This repository has been archived by the owner. It is now read-only.
```


```scala
addSbtPlugin("org.foundweekends" % "sbt-bintray" % "latest.release")
```

2) Редактируем build.sbt

Имя и организация. Влияет на название пакета (`organization %% name % version`)

```scala
name := "my-project"
organization := "com.example"
```

Ссылка на github репозиторий будет добавлена к bintray пакету:

```scala
bintrayVcsUrl := Some("https://github.com/username/repository.git")
```

Указывать лицензию - обязательно:

```scala
licenses += ("MIT", url("https://opensource.org/licenses/MIT"))
// или
licenses += ("Apache-2.0", url("https://opensource.org/licenses/Apache-2.0"))
```

## Настройка github workflows

1) Создаём файл `.github/workflows/publish.yml`:

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
        {% raw %}BINTRAY_USER: ${{ secrets.BINTRAY_USER }}
        BINTRAY_PASS: ${{ secrets.BINTRAY_PASS }}{% endraw %}
```

2) Достаём API Key из bintray

[Edit Profile](https://bintray.com/profile/edit) -> API Key -> Copy To Clipboard

3) Устанавливаем переменные `BINTRAY_USER`, `BINTRAY_PASS` для github workflows

На гитхабе Settings -> Secrets -> New Repository Secret

в переменную BINTRAY_PASS вставляем API Key

## Публикация новой версии пакета

Создаём тег. Тег начинается с `v`:

`git tag v0.1.4`

`git push --tags`

В гитхабе создаём релиз:

Releases -> v0.1.4 -> Edit tag

Вписываем Release title `0.1.4` и добавляем Release notes (потом можно редактировать)

-> Publish release

В этот момент запускается билд и публикация

Actions -> Bintray publish -> 0.1.4

## Подключение опубликованного пакета

Ammonite / Almond

```scala
interp.repositories() ++= Seq(
  coursierapi.MavenRepository
    .of("https://dl.bintray.com/username/maven")
)
```

```scala
import $ivy.`com.example::my-project:0.1.4`
```

SBT

```scala
resolvers += Resolver.bintrayRepo("username", "maven")
libraryDependencies += "com.example" %% "my-project" % "0.1.4"
```
