---
layout: post
title:  "Причёсывание XML с помощью Groovy"
date:   2016-01-10 22:00:00
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

Строим красивый XML и записываем в строку prettyXml
{% highlight groovy %}
String prettyXml = XmlUtil.serialize(new StreamingMarkupBuilder().bind {
    prettyNs.findAll { namespaces.contains(it.key) }.each { ns ->
        mkp.declareNamespace((ns.value): ns.key)
    }
    mkp.yield xml
})
{% endhighlight %}

Готово. Такой xml не стыдно добавить в документацию или еще куда нибудь.

### Откуда берется xml в котором нэймспэйсы не в корне?
XML, в котором нэймспэйсы дублируются и разбросаны по нодам получается при вставке элементов в существующий документ.
Например, в том же groovy это можно сделать так:

{% highlight groovy %}
String xmlString = '''\
<ns1:a xmlns:ns1="http://ns1" xmlns:ns2="http://ns2" xmlns:ns3="http://ns3">
    <ns2:b>
        <ns3:c>Test</ns3:c>
    </ns2:b>
</ns1:a>
'''
def xml = new XmlSlurper().parseText(xmlString)
xml.b.c.replaceNode {
    def newElement = '<ns10:x xmlns:ns10="http://ns10">10</ns10:x>'
    mkp.yield new XmlSlurper().parseText(newElement)
}
def actual = XmlUtil.serialize(xml)
def expected = XmlUtil.serialize('''\
<ns1:a xmlns:ns1="http://ns1">
  <ns2:b xmlns:ns2="http://ns2">
    <ns10:x xmlns:ns10="http://ns10">10</ns10:x>
  </ns2:b>
</ns1:a>''')
assert actual == expected
{% endhighlight %}

В groovy очень удобно парсить и менять xml. 
Еще он должен хорошо справляться с огромными документами, 
так как XmlSlurper и XmlParser основаны на SAX и используют мало памяти.
