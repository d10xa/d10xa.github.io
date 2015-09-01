---
layout: post
title:  "Зачем нужен gradle-download-xml-plugin?"
date:   2015-09-01 12:00:00
categories: gradle plugin
---

Для генерации java классов по wsdl-схеме существуют утилиты `xjc`, `wsimport` и др.
Утилитам дается URL на схему, по которой они генерируют классы. Но бывает такое,
что в схеме используются невалидные schemaLocation'ы.

Откуда растут ноги у этой проблемы? Для начала представим, что у нас есть wsdl-файл написанный руками,
например, `MyService.wsdl`
Рядом лежит еще один файлик `user.xsd`. В файле `MyService.wsdl` мы видим следующее:
{% highlight bash %}
<!-- ... -->
<xsd:import
   schemaLocation="user.xsd"
   namespace="http://example/user">
</xsd:import>
<!-- ... -->
{% endhighlight %}

Проверяем локально - всё красиво. IDE ошибок не находит, всё зелёное.
Отличный сервис! Опубликовали и забыли.

Теперь пытаемся сгенерировать клиент с помощью команд:
{% highlight bash %}
   xjc -wsdl http://my-site-name.ru/MyService.wsdl
{% endhighlight %}
или
{% highlight bash %}
   wsimport http://my-site-name.ru/MyService.wsdl
{% endhighlight %}

Ошибка: schemaLocation указывает на локальный файл.

Как решить проблему? Нужно скачать `MyService.wsdl`, посмотреть какие у него зависимости, скачать их, и положить рядом.
Если таких xsd файлов много и иерархия import'ов очень большая, то делать это всё руками довольно долго.
А так как схемы любят меняться без предупреждения мы не хотим каждый раз вручную всё пересохранять.

Для упрощения скачивания таких схем я написал плагин для gradle который делает всю грязную работу за нас.
Причем я хотел указать куда сохранять конкретный файл и под каким названием.

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

После выполнения команды `gradle downloadWsdl`, в папке build появятся наши файлы.