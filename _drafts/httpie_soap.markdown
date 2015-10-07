---
layout: post
title:  "Использование консольной утилиты HTTPie для отправки SOAP запросов"
date:   2015-10-07 12:00:00
categories: soap
---

В [одном из предыдущих постов]({% post_url 2015-09-01-gradle-download-xml-plugin %}) 
я показал пример веб сервиса, но не заиспользовал его. 
Сейчас я хочу исправить это и показать один из наиболее удобных (IMHO) способов общения с SOAP.

Для начала запустим сервис.

{% highlight bash %}
git clone https://github.com/d10xa/spring-boot-ws-bad-practice.git
cd spring-boot-ws-bad-practice
./gradlew bootRun -Pserver.port=8081
{% endhighlight %}

Создадим файл `request.xml` со следующим содержимым:

{% highlight xml %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:ws="http://d10xa.ru/schema/bad-practice/countries-service"
>
   <soapenv:Header/>
   <soapenv:Body>
      <ws:getCountryRequest>
         <ws:name>${name}</ws:name>
      </ws:getCountryRequest>
   </soapenv:Body>
</soapenv:Envelope>
{% endhighlight %}

Следует обратить внимание на плэйсхолдер `${name}`. 
При отправке сообщения мы будем его заменять на нужное нам значение с помощью [sed](https://ru.wikipedia.org/wiki/Sed) 

{% highlight bash %}
sed -e "s/\${name}/Spain/" request.xml | \
http POST :8081/ws/counties 'Content-Type:text/xml' -v
{% endhighlight %}

Ответ отображается в консоли с приятной подсветкой синтаксиса.

{% highlight xml %}
POST /ws/counties HTTP/1.1
Accept: application/json
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 315
Content-Type: text/xml
Host: localhost:8081
User-Agent: HTTPie/0.9.2

<ns0:Envelope xmlns:ns0="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:ns1="http://d10xa.ru/schema/bad-practice/countries-service">
    <ns0:Header />
    <ns0:Body>
        <ns1:getCountryRequest>
            <ns1:name>Spain</ns1:name>
        </ns1:getCountryRequest>
    </ns0:Body>
</ns0:Envelope>

HTTP/1.1 200 OK
Accept: text/xml, text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2
Content-Length: 477
Content-Type: text/xml;charset=utf-8
Date: Wed, 07 Oct 2015 09:46:48 GMT
SOAPAction: ""
Server: Apache-Coyote/1.1
X-Application-Context: application:8081

<ns0:Envelope xmlns:ns0="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:ns1="http://d10xa.ru/schema/bad-practice/countries-service" 
xmlns:ns2="http://d10xa.ru/schema/bad-practice/country">
    <ns0:Header />
    <ns0:Body>
        <ns1:getCountryResponse>
            <ns1:country>
                <ns2:name>Spain</ns2:name>
                <ns2:population>46704314</ns2:population>
                <ns2:capital>Madrid</ns2:capital>
                <ns2:currency>EUR</ns2:currency>
            </ns1:country>
        </ns1:getCountryResponse>
    </ns0:Body>
</ns0:Envelope>
{% endhighlight %}

Для сравнения, тот же запрос через curl.
В консоль выведется неотформатированное тело ответа, которое без дополнительной обработки невозможно читать.
{% highlight bash%}
sed -e "s/\${name}/Spain/" request.xml > curlrequest.xml
curl --header "content-type: text/xml" -d @curlrequest.xml http://localhost:8081/ws/counties
{% endhighlight %}

Утилита [HTTPie](http://httpie.org/) это curl для людей. 
Удобные команды.
Есть реализации под Linux, Mac OS, Windows. 
Есть подсветка синтаксиса и форматирование.
Что еще для счастья надо? Об этом можно почитать в репозитории [HTTPie](https://github.com/jkbrzt/httpie) на гитхабе