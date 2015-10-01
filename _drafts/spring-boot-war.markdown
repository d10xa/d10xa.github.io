---
layout: post
title:  Spring Boot War
date:   2015-10-01 12:00:00
categories: spring
---

Получаем Jetty Runner для запуска war
{% highlight bash %}
wget http://central.maven.org/maven2/org/eclipse/jetty/jetty-runner/9.3.3.v20150827/jetty-runner-9.3.3.v20150827.jar
{% endhighlight %}

Запускаем jetty runner
{% highlight bash %}
java -jar jetty-runner-9.3.3.v20150827.jar build/libs/foo.war
{% endhighlight %}


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

gradle clean build war
java -jar build/libs/foo.war

gradle clean war
java -jar build/libs/foo.war
# no main manifest attribute, in build/libs/foo.war