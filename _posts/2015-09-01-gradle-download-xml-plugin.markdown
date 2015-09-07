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

Но бывает такое, что в схеме используются локальные schemaLocation'ы
и данный способ генерации классов оказывается невозможным.
Валидным schemaLocation'ом является URL. Локальное имя файла это невалидный URL.

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

Если таких xsd файлов много и иерархия import'ов очень большая, то делать это всё руками довольно долго.

Используем gradle плагин ru.d10xa.download-xml
----------------------------------------------

Для упрощения скачивания таких схем я написал плагин для gradle который делает всю грязную работу за нас.

Пример файла `build.gradle`

{% highlight groovy %}
plugins {
    id 'ru.d10xa.download-xml' version '0.0.4'
}
task downloadWsdl << {
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
}


{% endhighlight %}

Во время первого запуска задачи не обязательно указывать `namespaceToFile`, gradle напишет в консоль подсказку,
какие нэймспэйсы он нашел.

После выполнения команды `gradle downloadWsdl`, в папке build появятся наши файлы.

Пример использования плагина
============================

Следующими командами запускаем soap сервис (localhost:8080)

{% highlight bash %}
git clone https://github.com/d10xa/spring-boot-ws-bad-practice.git
cd spring-boot-ws-bad-practice
./gradlew bootRun
{% endhighlight %}

Скачиваем схемы, строим классы, собираем jar

{% highlight bash %}
cd download-xml-plugin-example
./gradlew build
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