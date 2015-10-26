---
layout: post
title:  Spring Boot War
date:   2015-10-01 12:00:00
categories: spring
---

В релиз [Spring-Boot-1.3.0](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-1.3.0-Full-Release-Notes#spring-boot-cli) 
войдет возможность создавать war файлы следующей командой

{% highlight bash %}
$ spring war filename.war script.groovy

{% endhighlight %}

Причем, файл `script.groovy` довольно компактный. Никакие конфигурационные файлы не требуются.
{% highlight groovy %}
// script.groovy. Да, кроме него ничего не надо
package ru.d10xa.springwar;

@RestController
@RequestMapping('/')
class Ctrl{
    @RequestMapping
    def map(){
        return ['a':'b']
    }
}

{% endhighlight %}

Не смотря на то, что это WAR, он всё так же является 
[запускаемым](http://docs.spring.io/spring-boot/docs/current/reference/html/executable-jar.html).

Spring Boot поддерживает запускаемые jar и war файлы благодаря проекту spring-boot-loader.
По умолчанию, в java нет возможности загружать вложенные jar файлы. Этим занимаются загрузчики, 
которых spring подкидывает в проект при сборке.
В манифест добавляется строка `Main-Class: org.springframework.boot.loader.WarLauncher` (или JarLauncher). 
В WarLauncher есть public static void main который занимается запуском нашего приложения.

Можно запускать так:
{% highlight bash %}
java -jar filename.war

{% endhighlight %}

Или так:
{% highlight bash %}
wget http://central.maven.org/maven2/org/eclipse/jetty/jetty-runner/9.3.3.v20150827/jetty-runner-9.3.3.v20150827.jar
java -jar jetty-runner-9.3.3.v20150827.jar example.war

{% endhighlight %}

### Структура Jar

<pre>
example.jar
 |
 +-META-INF
 |  +-MANIFEST.MF
 +-org
 |  +-springframework
 |     +-boot
 |        +-loader
 |           +-&lt;spring boot loader classes&gt;
 +-com
 |  +-mycompany
 |     + project
 |        +-YouClasses.class
 +-lib
    +-dependency1.jar
    +-dependency2.jar
</pre>

### Структура War

<pre>
example.war
 |
 +-META-INF
 |  +-MANIFEST.MF
 +-org
 |  +-springframework
 |     +-boot
 |        +-loader
 |           +-&lt;spring boot loader classes&gt;
 +-WEB-INF
    +-classes
    |  +-com
    |     +-mycompany
    |        +-project
    |           +-YouClasses.class
    +-lib
    |  +-dependency1.jar
    |  +-dependency2.jar
    +-lib-provided
       +-servlet-api.jar
       +-dependency3.jar
</pre>

## Основные отличия WAR от JAR

* Строка указывающая на главный класс в MANIFEST.MF (JarLauncher, WarLauncher)
* Для War нужен класс наследник SpringBootServletInitializer
* Структура (Layout) архивов отличается
* В случае с war, зависимость `tomcat` помещается отдельно от основных зависимостей (lib-provided)

Утилитой [httpie](https://github.com/jkbrzt/httpie) проверяем работоспособность
{% highlight bash %}
http GET :8080
http GET :8080/ctrl
{% endhighlight %}

{% highlight bash %}
HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Date: Thu, 01 Oct 2015 10:06:26 GMT
Server: Jetty(9.3.3.v20150827)
Transfer-Encoding: chunked

{
    "abc": "xyz"
}
{% endhighlight %}


unzip -l build/libs/foo.jar > foo.jar.txt
unzip -l build/libs/foo.war > foo.war.txt

sdiff -w 240 foo.jar.txt foo.war.txt> foo.diff.txt
unzip build/libs/foo.jar -d unzipped_jar
unzip build/libs/foo.war -d unzipped_war
sdiff unzipped_jar/META-INF/MANIFEST.MF unzipped_war/META-INF/MANIFEST.MF

отличие:

Main-Class: org.springframework.boot.loader.JarLauncher       |	Main-Class: org.springframework.boot.loader.WarLauncher

ls -l unzipped_jar/org/springframework/boot/loader/

Оба класса присутствуют.

gradle clean build war
java -jar build/libs/foo.war

gradle clean war
java -jar build/libs/foo.war
# no main manifest attribute, in build/libs/foo.war