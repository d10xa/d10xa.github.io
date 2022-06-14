---
layout: post
title:  "Зачем нужен gradle-download-xml-plugin?"
date:   2015-09-01 12:00:00
categories: gradle plugin
---

## Обзор

Gradle Download Xml позволяет скачивать WSDL,XSD схемы со всеми зависимостями.

- [GitHub](https://github.com/d10xa/gradle-download-xml-plugin)
- [Gradle Plugin Portal](https://plugins.gradle.org/plugin/ru.d10xa.download-xml)

## Краткое описание проблемы

Для генерации java классов по wsdl-схеме существуют различные утилиты: `xjc`, `wsimport` и др.
Утилитам дается URL на схему, по которой они генерируют классы. Обычно это выглядит так:
{% highlight bash %}
xjc -wsdl http://my-site-name.ru/MyService.wsdl
{% endhighlight %}

Иногда, ошибочно, вместо валидного URL на ресурс, в аттрибуте `schemaLocation`, указываются локальные пути к файлам.
И данный способ генерации классов оказывается невозможным.

Пример невалидной схемы
{% highlight bash %}
<!-- ... -->
<xsd:import
   schemaLocation="user.xsd"
   namespace="http://example/user">
</xsd:import>
<!-- ... -->
{% endhighlight %}


## Как решить проблему вручную (без плагина)?

1. Скачиваем WSDL
2. Скачиваем все xsd из импортов (рекурсивно)
3. Исправляем schemaLocation'ы по необходимости
4. `xjc -wsdl local-file.wsdl`

Если таких xsd файлов много и иерархия import'ов очень большая - делать это руками довольно долго.

## Как выглядит решение проблемы gradle плагином ru.d10xa.download-xml

Плагин добавляет расширение downloadXml к задачам в gradle.

{% highlight groovy %}
downloadXml {
    src(['http://my-site-name.ru/MyService.wsdl'])
    dest buildDir
    namespaceToFile([
            'http://example/ws'   : 'service.wsdl',
            'http://example/user' : 'xsd/user.xsd',
    ])
    locations {
         malformedLocationHandler {
             "http://example/$it"
         }
    }
}
{% endhighlight %}

Во время первого запуска задачи, не обязательно указывать `namespaceToFile`. 
Gradle напишет в консоль нэймспэйсы, которые он нашел. Достаточно вставить их в блок `namespaceToFile([])`
и заменить расширения xml на wsdl и xsd, соответственно (необходимо для генерации классов).

## Пример плохого веб сервиса

О процессе создания SOAP веб сервиса можно почитать на [spring.io](https://spring.io/guides/gs/producing-web-service/).
В этом руководстве показана реализация веб сервиса использующего один файл xsd.

Исходники примера можно посмотреть на [гитхабе](https://github.com/d10xa/spring-boot-ws-bad-practice)

### Особенности примера:

1. Используем gradle для сборки
2. У нас есть 3 xsd схемы. WSDL генерируется при запуске сервера.
3. Сервис доступен по URL `$baseUrl/ws/countries.wsdl`
4. В проекте схемы находятся в директории `src/main/resources/static`.
К ним можно обратиться как к обычным статическим ресурсам $baseUrl/country.xsd, $baseUrl/currency.xsd

В jdk8 по умолчанию отключен доступ ко вложенным схемам.
Включить эту возможность можно определив системную переменную javax.xml.accessExternalSchema = all.

- all - дает доступ к внешним схемам по всем протоколам.

Создадим файл `$JAVA_HOME/jre/lib/jaxp.properties` со следующим содержимым:

{% highlight bash %}
javax.xml.accessExternalSchema = all
{% endhighlight %}

Подробнее о доступе можно почитать в [документации](http://docs.oracle.com/javase/8/docs/api/javax/xml/XMLConstants.html#ACCESS_EXTERNAL_SCHEMA)

### Запускаем веб сервис

Клонируем проект в локальную папку и запустим (порт 8081 можно заменить на любой свободный)

{% highlight bash %}
git clone https://github.com/d10xa/spring-boot-ws-bad-practice.git
cd spring-boot-ws-bad-practice
./gradlew bootRun -Pserver.port=8081
{% endhighlight %}

### Используем плагин

Перейдем в директорию download-xml-plugin-example (в проекте, рядом с веб сервисом).
В файле build.gradle описаны задачи:

- download - скачивает схемы в директорию build
- xjc - запускает ant задачу, генерирует классы. Классы создаются в директории `generated`
- build - собирает jar

Выполнив команду `./gradlew build`, мы скачаем схемы, сгенерируем классы и соберем jar.

{% highlight bash %}
cd download-xml-plugin-example
./gradlew build -Pbase.url=http://localhost:8081
{% endhighlight %}

## Ограниченный доступ к схемам

Иногда для доступа к схемам используется базовая HTTP-авторизация.
Для этого в расширение downloadXml добавим username, password:

{% highlight groovy %}
username 'foo'
password 'bar'
{% endhighlight %}