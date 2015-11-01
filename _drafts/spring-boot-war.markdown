---
layout: post
title:  Spring Boot War
date:   2015-10-01 12:00:00
categories: spring
---

В релиз [Spring-Boot-1.3.0](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-1.3.0-Full-Release-Notes#spring-boot-cli) 
войдет возможность создавать war файлы следующей командой

{% highlight bash %}
$ spring war example.war script.groovy

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

Spring Boot умеет создавать запускаемые jar и war файлы благодаря проекту spring-boot-loader.
По умолчанию, в java нет возможности загружать вложенные jar файлы. Этим занимаются загрузчики, 
которых spring подкидывает в проект при сборке.
В манифест добавляется строка `Main-Class: org.springframework.boot.loader.WarLauncher` (или JarLauncher). 
В WarLauncher есть public static void main который занимается запуском нашего приложения.

Можно запускать как обычный jar:
{% highlight bash %}
java -jar example.war

{% endhighlight %}

Или на jetty:
{% highlight bash %}
wget http://central.maven.org/maven2/org/eclipse/jetty/jetty-runner/9.3.3.v20150827/jetty-runner-9.3.3.v20150827.jar
java -jar jetty-runner-9.3.3.v20150827.jar example.war

{% endhighlight %}

Или на wildfly

{% highlight bash %}
# Dockerfile
FROM jboss/wildfly
ADD build/app.war /opt/jboss/wildfly/standalone/deployments/
{% endhighlight %}

{% highlight bash %}
docker build --tag=wildfly-app-war . 
docker run -it --rm -p 8080:8080 wildfly-app-war

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

## Перепаковка из jar в war (скриптом)

[исходники примера](https://github.com/d10xa/blog-examples/tree/master/spring-boot/spring-boot-cli-war)

Создадим класс, наследующийся от SpringBootServletInitializer (в той же директории, где script.groovy)

{% highlight groovy %}
package ru.d10xa.springwar;

import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.context.web.SpringBootServletInitializer;

public class ServletInitializer extends SpringBootServletInitializer {

   @Override
   protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
      return application.sources(Ctrl.class);
   }

}

{% endhighlight %}

Выполним скрипт:

{% highlight bash %}

# Удаляем директорию build
rm -rf build

# Создаем структуру war архива в build/tmp
mkdir -p build/tmp build/tmp/WEB-INF/ build/tmp/WEB-INF/classes/templates build/tmp/WEB-INF/lib build/tmp/WEB-INF/lib-provided

# Утилитой spring-boot-cli создаем jar
spring jar build/app.jar App.groovy ServletInitializer.groovy

# Распаковываем jar
unzip build/app.jar -d build/extracted_jar

# Библиотеки для встроенного сервера закидываем в папку lib-provided, остальные в lib
cp -p $(find build/extracted_jar/lib -name '*tomcat*') build/tmp/WEB-INF/lib-provided
cp -p $(find build/extracted_jar/lib -not -name '*tomcat*') build/tmp/WEB-INF/lib

# Копируем META-INF и спринговые классы в корень будующего war
cp -r build/extracted_jar/META-INF/ build/extracted_jar/org/ build/tmp/

# В манифесте меняем Main-Class JarLauncher на WarLauncher
sed -i -- 's/JarLauncher/WarLauncher/g' build/tmp/META-INF/MANIFEST.MF

# Копируем классы из пакета ru в WEB-INF/classes
cp -r build/extracted_jar/ru/ build/tmp/WEB-INF/classes

# Архивируем без сжатия, и размещаем war рядом с jar
cd build/tmp
zip -r --compression-method=store app.war *
mv app.war ../

{% endhighlight %}

Для сравнения, соберем war утилитой spring-boot-cli
{% highlight groovy %}
spring war build/spring-cli-app.war App.groovy

{% endhighlight %}


Сравним
{% highlight bash %}
scripts/zipdiff.groovy build/app.war build/spring-cli-app.war

{% endhighlight %}


<pre>

---unique in build/app.war
WEB-INF/classes/ru/d10xa/springwar/ServletInitializer.class
org/springframework/boot/cli/app/SpringApplicationLauncher.class
org/springframework/boot/cli/archive/PackagedSpringApplicationLauncher.class
---unique in build/spring-cli-app.war
WEB-INF/classes/org/springframework/boot/cli/app/SpringApplicationLauncher.class
WEB-INF/classes/org/springframework/boot/cli/app/SpringApplicationWebApplicationInitializer.class
WEB-INF/classes/org/springframework/boot/cli/archive/PackagedSpringApplicationLauncher.class
</pre>

[SpringApplicationWebApplicationInitializer](https://github.com/spring-projects/spring-boot/blob/master/spring-boot-cli/src/main/java/org/springframework/boot/cli/app/SpringApplicationWebApplicationInitializer.java)

## spring war VS gradle build

В архиве, собранном через spring-cli есть несколько файлов, которых нет в сборке gradle.
<pre>
WEB-INF/classes/org/springframework/boot/cli/app/SpringApplicationLauncher.class
WEB-INF/classes/org/springframework/boot/cli/app/SpringApplicationWebApplicationInitializer.class
WEB-INF/classes/org/springframework/boot/cli/archive/PackagedSpringApplicationLauncher.class
WEB-INF/lib/groovy-2.4.4.jar
WEB-INF/lib/groovy-templates-2.4.4.jar
WEB-INF/lib/groovy-xml-2.4.4.jar
org/springframework/boot/groovy/DelegateTestRunner.class
org/springframework/boot/groovy/DependencyManagementBom.class
org/springframework/boot/groovy/EnableDeviceResolver.class
org/springframework/boot/groovy/EnableGroovyTemplates.class
org/springframework/boot/groovy/GroovyTemplate.class
</pre>

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