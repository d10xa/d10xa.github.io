---
layout: post
title:  "Зачем нужен gradle-download-xml-plugin?"
date:   2015-09-01 12:00:00
categories: gradle plugin
---

Краткое описание проблемы
-------------------------

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


Как решить проблему вручную (без плагина)?
------------------------------------------

1. Скачиваем WSDL
2. Скачиваем все xsd из импортов (рекурсивно)
3. Исправляем schemaLocation'ы по необходимости
4. `xjc -wsdl local-file.wsdl`

Если таких xsd файлов много и иерархия import'ов очень большая - делать это руками довольно долго.

Как выглядит решение проблемы gradle плагином ru.d10xa.download-xml
-------------------------------------------------------------------

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

Пример плохого веб сервиса
==========================

О процессе создания SOAP веб сервиса на spring можно почитать на [spring.io][spring-producing-soap-guide]. 
В этом руководстве показана реализация веб сервиса использующего один файл xsd.

Исходники примера можно посмотреть на [гитхабе][spring-boot-ws-bad-practice]

Клонируем проект в локальную папку и запустим (порт 8081 можно заменить на любой свободный)

{% highlight bash %}
git clone https://github.com/d10xa/spring-boot-ws-bad-practice.git
cd spring-boot-ws-bad-practice
./gradlew bootRun -Pserver.port=8081
{% endhighlight %}

В папке `download-xml-plugin-example` находится пример использования плагина ru.d10xa.download-xml.
Выполнив команду `./gradlew build`, мы скачаем схемы, сгенерируем по ним классы и соберем jar.

{% highlight bash %}
cd download-xml-plugin-example
./gradlew build -Pbase.url=http://localhost:8081
{% endhighlight %}

Теперь пытаемся сгенерировать классы с помощью команд:
{% highlight bash %}
   xjc -wsdl http://my-site-name.ru/MyService.wsdl
{% endhighlight %}
или
{% highlight bash %}
   wsimport http://my-site-name.ru/MyService.wsdl
{% endhighlight %}

Ошибка. Не удалось получить импорты.

[spring-producing-soap-guide]:  https://spring.io/guides/gs/producing-web-service/
[spring-boot-ws-bad-practice]:  https://github.com/d10xa/spring-boot-ws-bad-practice
