---
layout: post
title:  "Поиск задач в jira с помощью Chrome Site Search"
date:   2023-02-11
categories: jira
permalink: /jira-chrome-site-search
---


В браузерах на базе Chromium есть возможность добавить поиск по любому сайту. Достаточным условием является возможность указать поисковую строку в URL. В этой статье я покажу, как искать задачи в jira таким способом.
Более продвинутый поиск можно сделать через скрипты Raycast.
Например, для поиска на сайте https://mvnrepository.com/ можно задать алиас `mvn` и искать сразу из поисковой строки браузера. (в строке поиска пишем `mvn TAB запрос`)

![Screenshot 2023-02-11 at 23.46.59.png](/images/Screenshot%202023-02-11%20at%2023.46.59.png)

## Как добавить сайт в Chrome Site Search

В google-chrome открываем настроики:

Settings - Search Engine - Manage search engines and site search - Site Search - Add

Для примера с mvn repository вводим следующее:
Search engine: mvnrepository
Shortcut: mvn
URL with %s in place of query: https://mvnrepository.com/search?q=%s

## Site Search для JIRA

![Screenshot 2023-02-12 at 00.33.16.png](/images/Screenshot%202023-02-12%20at%2000.33.16.png)

Поисковая строка для JIRA выглядит сложнее чем для других сайтов. Написать её руками и не ошибиться - дело не простое. Воспользуюсь скриптом. Буду искать issue в проекте zookeeper.

```python
from urllib.parse import urlencode

base_url = 'https://issues.apache.org/jira'
project = 'ZOOKEEPER'

issuekey = '%s'
terms = [
    f'issuekey={project}-REPLACE',
    f'issue in linkedIssues({project}-REPLACE)',
    f'text ~ "{project}-REPLACE"',
    f'issueFunction in linkedIssuesOfAll("issuekey={project}-REPLACE")'
]
jql = ' or '.join(terms)
query_string = urlencode({'jql': jql})  
url = f'{base_url}/browse/{project}-REPLACE/?' + query_string  
url_with_placeholder = url.replace('REPLACE', issuekey)  
print(url_with_placeholder)
```

Скрипт создаст следующую строку:

```
https://issues.apache.org/jira/browse/ZOOKEEPER-%s/?jql=issuekey%3DZOOKEEPER-%s+or+issue+in+linkedIssues%28ZOOKEEPER-%s%29+or+comment+~+%22ZOOKEEPER-%s%22+or+text+~+%22ZOOKEEPER-%s%22+or+issueFunction+in+linkedIssuesOfAll%28%22issuekey%3DZOOKEEPER-%s%22%29
```

Меняем `base_url` и `project` и получаем строку для своей jira. В скрипт можно легко добавить свои критерии поиска или убрать лишние.

- `issuekey` поиск по номеру задачи
- `issue in linkedIssues` задачи, которые ссылаются на искомую задачу
- `text` есть упоминание номера задачи в разделах: Summary, Description, Environment, Comments
- `issueFunction in linkedIssuesOfAll` - задачи, на которые ссылается искомая задача (Как `issue in linkedIssues`, но в обратную сторону)

![Screenshot 2023-02-12 at 00.27.28.png](/images/Screenshot%202023-02-12%20at%2000.27.28.png)

Добавляем в chrome и пользуемся
