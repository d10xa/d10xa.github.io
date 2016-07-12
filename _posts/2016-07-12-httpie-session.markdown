---
layout: post
title:  "HTTPie session"
date:   2016-07-12
categories: httpie
---

В HTTPie есть поддержка [сессий](https://github.com/jkbrzt/httpie#sessions)
По умолчанию каждый запрос не зависит от предыдущих. 
Параметр `--session` позволяет сохранять именованные сессии.

Для примера, возьмем spring-boot-cli приложение, требующее авторизацию.

{% highlight groovy %}
package org.test.security

import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder
import org.springframework.security.core.context.SecurityContextHolder

@Grab("spring-boot-starter-security")
@Grab("spring-boot-starter-actuator")

@RestController
@EnableWebSecurity
class PrincipalController {

    @RequestMapping("/")
    public def principal() {
        [principal: SecurityContextHolder.getContext().getAuthentication().getPrincipal()]
    }

}

@Configuration
class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    void configure(HttpSecurity http) {
        http
            .csrf()
            .disable()
            .authorizeRequests()
            .anyRequest().authenticated()
            .and()
            .formLogin()
            .and()
            .httpBasic();

    }

    @Autowired
    public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
        auth
            .inMemoryAuthentication()
            .withUser("user").password("password").roles("USER");
    }

}
{% endhighlight %}

Запускаем 

    spring run secure.groovy -- --server.port=8081

При отправке GET запроса получаем редирект на страницу /login

    $ http GET :8081 -v

    GET / HTTP/1.1
    Accept: */*
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Host: localhost:8081
    User-Agent: HTTPie/0.9.4
    
    
    
    HTTP/1.1 302 Found
    Cache-Control: no-cache, no-store, max-age=0, must-revalidate
    Content-Length: 0
    Date: Tue, 12 Jul 2016 11:24:52 GMT
    Expires: 0
    Location: http://localhost:8081/login
    Pragma: no-cache
    Server: Apache-Coyote/1.1
    Set-Cookie: JSESSIONID=946815F8998A9910568DA2B4EEFA1189; Path=/; HttpOnly
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    
Авторизуемся и сохраним сессию как session1

    $ http POST :8081/login username==user password==password --session=session1 -v
    
    POST /login?username=user&password=password HTTP/1.1
    Accept: */*
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Content-Length: 0
    Host: localhost:8081
    User-Agent: HTTPie/0.9.4
    
    
    
    HTTP/1.1 302 Found
    Cache-Control: no-cache, no-store, max-age=0, must-revalidate
    Content-Length: 0
    Date: Tue, 12 Jul 2016 11:33:04 GMT
    Expires: 0
    Location: http://localhost:8081/
    Pragma: no-cache
    Server: Apache-Coyote/1.1
    Set-Cookie: JSESSIONID=3C3571A04EADE8F60C03F0AF07D42C2E; Path=/; HttpOnly
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block

Информация о сессии хранится в файле `~/.httpie/sessions/localhost_8081/session1.json`
в виде json

    {
        "__meta__": {
            "about": "HTTPie session file",
            "help": "https://github.com/jkbrzt/httpie#sessions",
            "httpie": "0.9.4"
        },
        "auth": {
            "password": null,
            "type": null,
            "username": null
        },
        "cookies": {
            "JSESSIONID": {
                "expires": null,
                "path": "/",
                "secure": false,
                "value": "3C3571A04EADE8F60C03F0AF07D42C2E"
            }
        },
        "headers": {}
    }

Повторим GET запрос с сессией session1
    
    $ http GET :8081 -v --session=session1
    
    GET / HTTP/1.1
    Accept: */*
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Cookie: JSESSIONID=3C3571A04EADE8F60C03F0AF07D42C2E
    Host: localhost:8081
    User-Agent: HTTPie/0.9.4
    
    
    
    HTTP/1.1 200 OK
    Cache-Control: no-cache, no-store, max-age=0, must-revalidate
    Content-Type: application/json;charset=UTF-8
    Date: Tue, 12 Jul 2016 11:35:58 GMT
    Expires: 0
    Pragma: no-cache
    Server: Apache-Coyote/1.1
    Transfer-Encoding: chunked
    X-Application-Context: application:8081
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    
    {
        "principal": {
            "accountNonExpired": true,
            "accountNonLocked": true,
            "authorities": [
                {
                    "authority": "ROLE_USER"
                }
            ],
            "credentialsNonExpired": true,
            "enabled": true,
            "password": null,
            "username": "user"
        }
    }

HTTPie умеет ходить по редиректам. Для этого используется флаг --follow. 

    $ http POST :8081/login username==user password==password --session=session2 --follow -v
    
    POST /login?username=user&password=password HTTP/1.1
    Accept: */*
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Content-Length: 0
    Host: localhost:8081
    User-Agent: HTTPie/0.9.4
    
    
    
    HTTP/1.1 302 Found
    Cache-Control: no-cache, no-store, max-age=0, must-revalidate
    Content-Length: 0
    Date: Tue, 12 Jul 2016 11:39:34 GMT
    Expires: 0
    Location: http://localhost:8081/
    Pragma: no-cache
    Server: Apache-Coyote/1.1
    Set-Cookie: JSESSIONID=6EB2E625EA05273F17545014B470D6B0; Path=/; HttpOnly
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    
    
    
    GET / HTTP/1.1
    Accept: */*
    Accept-Encoding: gzip, deflate
    Connection: keep-alive
    Cookie: JSESSIONID=6EB2E625EA05273F17545014B470D6B0
    Host: localhost:8081
    User-Agent: HTTPie/0.9.4
    
    
    
    HTTP/1.1 200 OK
    Cache-Control: no-cache, no-store, max-age=0, must-revalidate
    Content-Type: application/json;charset=UTF-8
    Date: Tue, 12 Jul 2016 11:39:34 GMT
    Expires: 0
    Pragma: no-cache
    Server: Apache-Coyote/1.1
    Transfer-Encoding: chunked
    X-Application-Context: application:8081
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    
    {
        "principal": {
            "accountNonExpired": true,
            "accountNonLocked": true,
            "authorities": [
                {
                    "authority": "ROLE_USER"
                }
            ],
            "credentialsNonExpired": true,
            "enabled": true,
            "password": null,
            "username": "user"
        }
    }

В сессию можно добавить заголовки вручную. (Например, вытащить из браузера)

    $ http GET :8081 Cookie:JSESSIONID=C63B511FC3DA427D80583192043FCFBC -v --session=session3
