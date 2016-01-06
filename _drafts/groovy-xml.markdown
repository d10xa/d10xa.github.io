---
layout: post
title:  "Причёсывание XML с помощью Groovy"
date:   2016-01-06 21:00:00
categories: groovy xml
---

Дано:

 - неиспользуемые нэймспэйсы
 - дублирование нэймспэйсов
 - нэймспэйсы раскиданы по разным элементам

{% highlight xml %}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:unused="http://unused.ns">
    <soapenv:Header/>
    <soapenv:Body>
        <ns1:GetWeather xmlns:ns1="http://weather">
            <ns2:CityName xmlns:ns2="http://help.weather">Vladimir</ns2:CityName>
            <ns2a:CountryName xmlns:ns2a="http://help.weather">Russian Federation</ns2a:CountryName>
        </ns1:GetWeather>
    </soapenv:Body>
</soapenv:Envelope>
{% endhighlight %}

Хотим получить:

 - все нэймспэйсы перечислены в корневом элементе
 - отсутствуют неиспользованные
 - отсутствует дублирование
 - алиасы заменены на "красивые"

{% highlight xml %}
<e:Envelope
        xmlns:e="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:w="http://weather"
        xmlns:h="http://help.weather">
  <e:Header/>
  <e:Body>
    <w:GetWeather>
      <h:CityName>Vladimir</h:CityName>
      <h:CountryName>Russian Federation</h:CountryName>
    </w:GetWeather>
  </e:Body>
</e:Envelope>
{% endhighlight %}

Воспользуемся встроенным в groovy xml-парсером (XmlSlurper)

{% highlight groovy %}
String xmlString = new File('soap1.xml').text
GPathResult xml = new XmlSlurper().parseText(xmlString)
{% endhighlight %}

Вытащим все нэймспэйсы из xml документа и уберем дубликаты.
{% highlight groovy %}
List<String> namespaces = xml.'**'.collect { it.namespaceURI() }.unique()
{% endhighlight %}

Убедимся, что в списке нет неиспользуемых нэймспэйсов (xmlns:unused="http://unused.ns")
{% highlight groovy %}
assert ['http://schemas.xmlsoap.org/soap/envelope/',
        'http://weather',
        'http://help.weather'] == namespaces
{% endhighlight %}

Создадим карту соответствия namespace:alias
{% highlight groovy %}
def prettyNs = ['http://schemas.xmlsoap.org/soap/envelope/': 'e',
                'http://weather'                           : 'w',
                'http://help.weather'                      : 'h',
                'http://unused.ns'                         : 'unused']
{% endhighlight %}

Строим красивый XML 
{% highlight groovy %}
String prettyXml = XmlUtil.serialize(new StreamingMarkupBuilder().bind {
    prettyNs.findAll { namespaces.contains(it.key) }.each { ns ->
        mkp.declareNamespace((ns.value): ns.key)
    }
    mkp.yield xml
})
{% endhighlight %}
