---
layout: post
title:  "Spring Boot приложение в облаке OpenShift(java-8, mongodb-3)"
date:   2015-11-21 19:00:00
categories: cloud
---

OpenShift - хостинг веб приложений. 
По умолчанию можно создать приложение с tomcat7, java7, mongodb2.4... Всё это давно устарело.
Если хотим чтото поновее или то, чего вообще нет среди предложенного - пишем сами (или ищем уже готовое на гитхабе)

Можно создавать приложения и добавлять картриджи двумя способами:

- Консольная утилита [rhc](https://developers.openshift.com/en/managing-client-tools.html)
- Браузер

## Создание приложения на OpenShift:

В примере создается приложение с названием demo.

За основу берем репозиторий с гитхаба 
[kolorobot/openshift-diy-spring-boot-gradle](https://github.com/kolorobot/openshift-diy-spring-boot-gradle)

Можно(но не обязательно) заранее создать свой репозиторий и использовать его в качестве основы. 
В корне должна находиться папка .openshift/action_hooks и 3 файла внутри:

 - start - Запуск приложения
 - stop - Остановка приложения
 - deploy - Установка jdk, gradle (если не установлены) + сборка приложения
 
файлы deploy, start, stop должны быть исполняемыми:

{% highlight bash %}
chmod +x .openshift/action_hooks/{deploy,start,stop}

{% endhighlight %}

### Создаем приложение утилитой rhc

{% highlight bash %}
sudo apt-get install rhc
rhc app create demo diy-0.1
cd demo
git rm -rf .openshift README.md diy misc
git commit -am "Removed template application source code"
git remote add upstream https://github.com/kolorobot/openshift-diy-spring-boot-gradle.git
git pull -s recursive -X theirs upstream master
git push

{% endhighlight %}

### Создаем приложение через GUI в браузере

<pre>
https://openshift.redhat.com/app/console/applications
кнопка "Add Application…"
ищем тип приложения по слову diy
выбираем Do-It-Yourself 0.1
Public URL: указываем название приложения
Source Code: https://github.com/kolorobot/openshift-diy-spring-boot-gradle.git
кнопка "Create Application"
</pre>

## Добавление картриджа с mongodb

Картридж с mongodb так же находим на гитхабе [icflorescu/openshift-cartridge-mongodb](https://github.com/icflorescu/openshift-cartridge-mongodb)

### Добавляем картридж через утилиту rhc

{% highlight bash %}
rhc add-cartridge http://cartreflect-claytondev.rhcloud.com/github/icflorescu/openshift-cartridge-mongodb --app demo

{% endhighlight %}

### Добавляем картридж через браузер

<pre>
Install your own cartridge
http://cartreflect-claytondev.rhcloud.com/github/icflorescu/openshift-cartridge-mongodb
Next
</pre>

## Подключение к mongodb из spring-boot

Добавляем зависимость в build.gradle

{% highlight bash %}
compile "org.springframework.boot:spring-boot-starter-data-mongodb"
    
{% endhighlight %}

Создадим файл `src/main/resources/application-openshift.properties`,
запишем в него следующую строку, где `demo`- название базы.

<pre>
spring.data.mongodb.uri=${MONGODB_URL}demo
</pre>

## Логи

Чтобы указать директорию, куда мы хотим писать логи приложения, 
нужно отредактировать файл `.openshift/action_hooks/start`

В запуск jar допишем параметр `--logging.file=${OPENSHIFT_LOG_DIR}app.log`

## Как деплоить

Не смотря на то, что в OpenShift есть git репозиторий, совсем не обязательно использовать его как основной.
 
Я выбрал такую стратегию: 
Создал репозиторий на [bitbucket](https://bitbucket.org/) и там держу исходники.
А когда надо задеплоить - делаю push на OpenShift.

Как это сделать, подробно описано на [stackoverflow](http://stackoverflow.com/a/12669112)

## Что получилось

По url `demo-username.rhcloud.com` доступно только что созданное приложение.

Установлены

- jdk1.8.0_65
- gradle-2.7
- mongodb 3.0.7

Приложение пакуется в jar и запускается обычным способом (java -jar ...)


