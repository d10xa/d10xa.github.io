---
layout: post
title:  "log4cats. Почему нужно использовать LoggerFactory"
date:   2025-03-06
categories:
  - scala
permalink: /log4cats-logger-factory
---

# Правильный подход к организации логирования с log4cats

При использовании log4cats велик соблазн передавать везде неявно Logger,
в этом посте хочу показать как это сделать правильно.

## Неправильный подход: Logger

Рассмотрим сначала распространенную, но не рекомендуемую практику —
создание одного общего логгера и его передачу в компоненты приложения:

```scala
#!/usr/bin/env -S scala-cli shebang
//> using scala 2.13.12
//> using dep org.typelevel::log4cats-core:2.7.0
//> using dep org.typelevel::log4cats-slf4j:2.7.0
//> using dep ch.qos.logback:logback-classic:1.5.17

import cats.effect._
import org.typelevel.log4cats._
import org.typelevel.log4cats.slf4j.Slf4jFactory
import cats.syntax.all._

object LoggerExample extends IOApp.Simple {
  implicit val logging: LoggerFactory[IO] = Slf4jFactory.create[IO]

  class Service[F[_]: Async: Logger] {
    def doSomething(value: String): F[Unit] = 
      Logger[F].info(s"Service processing: $value")
  }

  class Application[F[_]: Async](implicit L: LoggerFactory[F]) {
    private val logger = L.getLogger
    
    implicit private val loggerInstance: Logger[F] = logger

    def run: F[Unit] = for {
      _ <- logger.info("Application starting")
      service = new Service[F]
      _ <- service.doSomething("test")
      _ <- logger.info("Application finished")
    } yield ()
  }

  def run: IO[Unit] = new Application[IO].run
}
```

### Проблема данного подхода

**Потеря информации о происхождении логов**: все логи имеют одинаковый источник (`LoggingExample.Application`), что затрудняет отладку:
   ```
   [INFO] LoggingExample.Application - Application starting
   [INFO] LoggingExample.Application - Service processing: test  // Источник лога не Service
   [INFO] LoggingExample.Application - Application finished
   ```

## Правильный подход: LoggerFactory в каждом классе

Более корректный подход — использование `LoggerFactory` для создания отдельных логгеров в каждом компоненте:

```scala
#!/usr/bin/env -S scala-cli shebang
//> using scala 2.13.12
//> using dep org.typelevel::log4cats-core:2.7.0
//> using dep org.typelevel::log4cats-slf4j:2.7.0
//> using dep ch.qos.logback:logback-classic:1.5.17

import cats.effect._
import org.typelevel.log4cats._
import org.typelevel.log4cats.slf4j.Slf4jFactory
import cats.syntax.all._

object LoggerFactoryExample extends IOApp.Simple {
  implicit val logging: LoggerFactory[IO] = Slf4jFactory.create[IO]

  class Service[F[_]: Async](implicit L: LoggerFactory[F]) {
    private val logger = L.getLogger
    
    def doSomething(value: String): F[Unit] = 
      logger.info(s"Service processing: $value")
  }

  class Application[F[_]: Async](implicit L: LoggerFactory[F]) {
    private val logger = L.getLogger

    def run: F[Unit] = for {
      _ <- logger.info("Application starting")
      service = new Service[F]
      _ <- service.doSomething("test")
      _ <- logger.info("Application finished")
    } yield ()
  }

  def run: IO[Unit] = new Application[IO].run
}
```

### Результат логирования:

```
[INFO] LoggingExample.Application - Application starting
[INFO] LoggingExample.Service - Service processing: test  // Источник лога правильный
[INFO] LoggingExample.Application - Application finished
```

## Выводы

Использование `LoggerFactory` в каждом классе предпочтительнее по следующим причинам:

1. **Точное указание источника логов**: легко определить, какой компонент создал лог-запись
2. **Гибкость конфигурирования**: возможность настройки различных уровней логирования для отдельных компонентов
