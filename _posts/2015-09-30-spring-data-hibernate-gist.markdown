---
layout: post
title:  "Быстрое прототипирование Hibernate маппингов и сохранение проекта на GitHub Gist"
date:   2015-09-30 12:00:00
categories: hibernate
---

При чтении документации по hibernate возникает желание воспроизвести примеры маппингов,
но для этого нужно писать конфиги, создавать структуру проекта, добавлять зависимости и всё такое.
Когда не хочется делать это всё самому, можно воспользоваться примером из этой статьи.

Сохранить свой пример можно на [GitHub Gist](https://gist.github.com).
Там есть ограничение - все файлы расположены в одной директории. Наши исходники должны лежать в корне проекта.

### Что представляет из себя пример:

 - весь код на Groovy. Он лаконичнее чем java -> сильно меньше кода
 - конфигурацией занимается Spring Boot
 - В проекте 3 файла. Все лежат в одной директории
 - сборщик - Gradle

### Файлы:

 - файл Application.groovy - сущности и репозитории
 - файл Spec.groovy - spock тест
 - файл build.gradle

### Структура gradle проекта(по умолчанию) выглядит следующим образом:

* src/main/java - исходники java для продакшена
* src/test/java - исходники java для тестов
* src/main/groovy - исходники groovy для продакшена
* src/test/groovy - исходники groovy для тестов

Продакшн нам в данном случае не интересен.
Переопределим директорию тестовых groovy исходников чтобы они искались в корне проекта, рядом с build.gradle.
{% highlight groovy %}
//build.gradle
sourceSets.test.groovy {
    srcDir projectDir.absolutePath
}
{% endhighlight %}

### Запускаем пример с GitHub Gist
{% highlight bash %}
git clone https://gist.github.com/c9ce30139b7dfeac0702.git
cd c9ce30139b7dfeac0702
gradle test
{% endhighlight %}

### Комментарии

В файле Application.groovy описан класс Language и интерфейс LanguageRepository.

Language - jpa сущность, которую будем сохранять и читать из базы

LanguageRepository - репозирорий, реализацией которого занимается
[Spring Data](http://projects.spring.io/spring-data/) в рантайме.

В build.gradle подключаем зависимости, в том числе 'com.h2database:h2' базу данных.

upToDateWhen { false } // запускаем тесты даже если у нас не изменились исходники

[Исходники примера](https://gist.github.com/d10xa/c9ce30139b7dfeac0702)
