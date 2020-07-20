---
layout: post
title:  "[WIP] Using cats.effect.Resource in jupyter (almond) notebook"
date:   2020-07-20
categories: scala
permalink: /cats-resource-almond
---

`cats.effect.Resource` provides mehtod `use` to interact with some resource.
 But there are resources that need to be used not only within one method.

It is more convenient to define some resource in the notebook in place
and hope it frees itself when the kernel stops

I couldn't find the generally accepted solution and wrote my own.
 The code is self-contained, all imports are included.
 

```scala
import $ivy.`org.typelevel::cats-effect:2.1.3`
import cats.effect._
import cats.effect.concurrent.Deferred
import cats.effect.concurrent.MVar
import scala.concurrent.ExecutionContext
import java.util.concurrent.Executors
import cats.implicits._

val blockingPool = ExecutionContext.fromExecutor(Executors.newFixedThreadPool(5))
implicit val cs: ContextShift[IO] = IO.contextShift(blockingPool) // or scala.concurrent.ExecutionContext.global
def resourceDefer[F[_]: Concurrent: ContextShift, A](resource: Resource[F, A]): F[(Either[Throwable, A], Deferred[F, Unit])] =
    for {
        deferred <- Deferred[F, Unit]
        mvar <- MVar.empty[F, Either[Throwable, A]]
        _ <- Concurrent[F].start(
            resource
                .use(r => mvar.put(r.asRight).flatMap(_ => deferred.get))
                .recoverWith(e => mvar.put(e.asLeft).flatMap(_ => deferred.get))
        )
        resourceAcquired <- mvar.read
    } yield (resourceAcquired, deferred)
def resourceUseInAlmondBackground[A](resource: Resource[IO, A]): A =
    resourceDefer[IO, A](resource).map { 
        case (Right(r), deferred) =>
            interp.beforeExitHooks += { _ =>
                deferred.complete().unsafeRunSync
            }
            r
        case (Left(e), _) => throw e
    }.unsafeRunSync


```
