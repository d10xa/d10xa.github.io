---
layout: post
title:  "Geb. Как начать писать UI-тесты веб-приложений"
date:   2015-09-16 12:00:00
categories: geb
---

UI-тесты желательно держать в отдельном проекте, не зависимым от основного.
Я использую директорию `test-ui` в корне тестируемого проекта.

Простейший тест выглядит следующим образом:

{% highlight groovy %}
// src/test/groovy/YandexSearchSpec.groovy
import geb.spock.GebSpec

class YandexSearchSpec extends GebSpec {

    void 'search wikipedia'() {
        go 'https://ya.ru/'
        $('#text') << 'wikipedia'
        $('button', text: 'Найти').click()
        waitFor { title.contains('wikipedia') }

        expect:
        $('a', href: 'https://ru.wikipedia.org/').displayed
    }
}
{% endhighlight %}

Без комментариев понятно что происходит.

Для того, чтобы запустить такой тест нужно подключить gradle-плагин.

{% highlight groovy %}
// build.gradle
buildscript {
    repositories {
        maven { url 'https://dl.bintray.com/d10xa/maven' }
        jcenter()
    }
    dependencies {
        classpath "ru.d10xa:gradle-geb-plugin:1.0.3"
    }
}
apply plugin: 'groovy'
apply plugin: 'ru.d10xa.geb'

repositories {
    jcenter()
}
{% endhighlight %}

Запустим тесты и убедимся что они работают.
{% highlight bash %}
gradle test
{% endhighlight %}

Определить браузер по умолчанию можно, добавив в `build.gradle` следующий параметр:
{% highlight groovy %}
geb {
   defaultTestBrowser = 'firefox'
}
{% endhighlight %}

Чтобы в каждом тесте не указывать baseUrl можно вынести его в конфигурацию.
В тесте заменим первую строку на `go baseUrl`
{% highlight groovy %}
// src/test/resources/GebConfig.groovy
baseUrl = "https://ya.ru"
{% endhighlight %}

Вынесем логику поиска в page-object.

{% highlight groovy %}
//src/test/groovy/YandexSearchSpec.groovy
import geb.spock.GebSpec

class YandexSearchSpec extends GebSpec {

    def 'search wikipedia'() {
        to YandexHomePage
        search 'wikipedia'

        expect:
        $('a', href: 'https://ru.wikipedia.org/').displayed
    }

}

//src/test/groovy/YandexHomePage.groovy
import geb.Page

class YandexHomePage extends Page {
    static url = "/"

    void search(value){
        $('#text') << value
        $('button', text: 'Найти').click()
        waitFor { title.contains(value) }
    }

}

{% endhighlight %}

Для начала достаточно. Подробную инструкцию по geb можно найти [тут](http://www.gebish.org/manual/current/)

- [geb](http://www.gebish.org)
- [gradle-geb-plugin](https://github.com/d10xa/gradle-geb-plugin)