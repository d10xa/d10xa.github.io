---
layout: post
title:  "TodoApp. scala-cli + http4s"
date:   2024-01-27
categories: 
  - scala
permalink: /todoapp-scala-cli-http4s
---

Представленный код - это сниппет TODO-приложения.
Он написан для Scala CLI, включает все необходимые зависимости и готов к запуску как есть.
В коде используются HTTP4S и Circe.
Сниппет демонстрирует создание простого REST API для управления задачами: добавление, просмотр и удаление задач.

## Код http4s-сервера для TODO-сервиса

```scala
#!/usr/bin/env scala-cli

//> using scala "2.12"
//> using dep "org.http4s::http4s-ember-server:1.0.0-M30"
//> using dep "org.http4s::http4s-dsl:1.0.0-M30"
//> using dep "org.typelevel::log4cats-slf4j:2.6.0"
//> using dep "ch.qos.logback:logback-classic:1.4.14"
//> using dep "io.circe::circe-generic:0.14.1"
//> using dep "org.http4s::http4s-circe:1.0.0-M30"

import cats.effect._
import org.http4s._
import org.http4s.dsl.io._
import cats.syntax.all._
import com.comcast.ip4s._
import org.http4s.ember.server._
import org.http4s.implicits._
import org.http4s.server.Router
import org.typelevel.log4cats.LoggerFactory
import org.typelevel.log4cats.slf4j.Slf4jFactory
import scala.concurrent.duration._
import org.http4s.server.Server
import io.circe.generic.auto._
import org.http4s.circe._


class TodoList(ref: Ref[IO, List[TodoApp.TodoItem]]) {
  import TodoApp._
  private var nextId = 1

  def addTask(task: String): IO[TodoItem] = {
    val newItem = TodoItem(nextId, task)
    nextId += 1
    ref.update(newItem :: _) *> IO.pure(newItem)
  }

  def getAllTasks: IO[TodoListResponse] = ref.get.map(TodoListResponse)

  def removeTask(id: Int): IO[Option[TodoItem]] = {
    ref.modify { todos =>
      val (remaining, removed) = todos.partition(_.id != id)
      (remaining, removed.headOption)
    }
  }
}

object TodoApp extends IOApp.Simple {

  import org.http4s.circe.CirceEntityCodec._
  
  case class TodoItem(id: Int, task: String)
  case class CreateTodoItem(task: String)
  case class TodoListResponse(todos: List[TodoItem])

  val todoList: IO[TodoList] =
    Ref.of[IO, List[TodoItem]](List.empty).map(new TodoList(_))

  val server: IO[Resource[IO, Server]] = todoList.map { list =>
    val todoService = HttpRoutes.of[IO] {
      case req @ POST -> Root / "todo" =>
        for {
          createItem <- req.as[CreateTodoItem]
          item <- list.addTask(createItem.task)
          resp <- Ok(item)
        } yield resp

      case GET -> Root / "todo" =>
        list.getAllTasks.flatMap(Ok(_))

      case DELETE -> Root / "todo" / IntVar(id) =>
        list.removeTask(id).flatMap {
          case Some(item) => Ok(item)
          case None       => NotFound()
        }
    }

    val httpApp = Router("/" -> todoService).orNotFound
    EmberServerBuilder
      .default[IO]
      .withHost(ipv4"0.0.0.0")
      .withPort(port"8080")
      .withHttpApp(httpApp)
      .build
  }

  override def run: IO[Unit] =
    server.flatMap(_.use(_ => IO.never))
}

```

## Запросы к сервису (curl)

Для тестирования приложения можно воспользоваться следующими запросами:

1. **Добавление задачи в список TODO:**

    ```bash
    curl -X POST -H "Content-Type: application/json" -d '{"task":"Новая задача"}' http://localhost:8080/todo
    ```

2. **Получение списка всех задач:**

    ```bash
    curl -X GET http://localhost:8080/todo
    ```

3. **Удаление задачи из списка:**

    ```bash
    curl -X DELETE http://localhost:8080/todo/{id}
    ```

## Клиент http4s-blaze-client

```scala
#!/usr/bin/env scala-cli

//> using scala "2.12"
//> using lib "org.http4s::http4s-blaze-client:1.0.0-M30"
//> using lib "org.http4s::http4s-circe:1.0.0-M30"
//> using lib "io.circe::circe-generic:0.14.1"
//> using lib "org.typelevel::cats-effect:3.5.3"
//> using dep "ch.qos.logback:logback-classic:1.4.14"

import cats.effect._
import org.http4s._
import org.http4s.client._
import org.http4s.client.blaze._
import org.http4s.circe._
import org.http4s.client.dsl.io._
import io.circe.generic.auto._
import io.circe.syntax._


object TodoClientApp extends IOApp.Simple {

   case class CreateTodoItem(task: String)
   case class TodoItem(id: Int, task: String)
   case class TodoListResponse(todos: List[TodoItem])

   implicit val todoItemDecoder: EntityDecoder[IO, TodoItem] =
      jsonOf[IO, TodoItem]
   implicit val todoListDecoder: EntityDecoder[IO, TodoListResponse] =
      jsonOf[IO, TodoListResponse]
   implicit val createTodoItemEncoder: EntityEncoder[IO, CreateTodoItem] =
      jsonEncoderOf[CreateTodoItem]

   def run(): IO[Unit] = {
      val uri = Uri.uri("http://localhost:8080/todo")

      val clientResource = BlazeClientBuilder[IO].resource

      clientResource.use { client =>
         for {
            postResp <- client.expect[TodoItem](
               Request[IO](Method.POST, uri)
                       .withEntity(CreateTodoItem("buy milk").asJson)
            )
            _ <- IO(println(s"New todo: ${postResp.asJson}"))
            
            getResp <- client.expect[TodoListResponse](uri)
            _ <- IO(println(s"List todoes: ${getResp.asJson}"))

            deleteResp <- client.expect[TodoItem](
               Request[IO](Method.DELETE, uri / postResp.id.toString)
            )
            _ <- IO(println(s"Deleted todo: ${deleteResp.asJson}"))
         } yield ()
      }
   }
}

```

## Заключение

В этой статье я представил сниппеты для сервера и клиента,
использующих HTTP4S, а также CURL-запросы для взаимодействия с сервером
