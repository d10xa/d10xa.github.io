---
layout: post
title:  "Зачем flatMap на tuple"
date:   2021-03-17
categories: scala
permalink: /flatmap-tuple
---

Всем понятно какой практический смысл у flatMap на коллекциях, Option, IO итд. 
Я раньше не задумывался, зачем он может понадобиться на туплах и что он вообще делает с ними.
Нашел для себя практическое применение и напишу об этом.
Задачу можно решить больше чем одним способом. Не готов утверждать, что этот - лучший.

## Какая задача?

Нужно посчитать количество модификаций коллекции.

Пример:

```scala
List(1, 2, 3, 4, 5).map {
  case i if i % 2 == 0 => i * 2
  case i => i
}
```

Результат:

```scala
List(1, 4, 3, 8, 5)
```

Количество измененных элементов == 2 (Хочу получить это число)

## А в чём проблема?

Переписать функцию не сложно. Можно вместо map использовать foldLeft:

```scala
List(1, 2, 3, 4, 5).foldLeft(0, List.empty[Int]) {
  case (acc, i) if i % 2 == 0 => (acc._1 + 1, acc._2 :+ (i * 2))
  case (acc, i) => (acc._1, acc._2 :+ i)
}
```

Или separate + leftMap:

```scala
List(1, 2, 3, 4, 5)
  .map {
    case i if i % 2 == 0 => (1, i * 2)
    case i => (0, i)
  }
  .separate
  .leftMap(_.sum)
```

Сложность в композиции. Нужно продолжать цепочку вычислений,
а у нас вместо коллекции теперь кортеж из числа и коллекции.

```scala
List(1, 2, 3, 4, 5)
  .map(functionWithTupleOutput).separate.leftMap(_.sum) // (2,List(1, 4, 3, 8, 5))
  .map(functionWithTupleOutput) // Ошибка компиляции
```

## FlatMap для Tuple2 спешит на помощь

Изначально я написал свой велосипед, затем я решил покопаться в cats instances для tuple. 
Был удивлён, что в cats есть flatMap на туплах и делает он именно то, что я имплементировал.
Он выглядит так (s это Semigroup):

```scala
def flatMap[A, B](fa: (X, A))(f: A => (X, B)): (X, B) = {
  val xb = f(fa._2)
  val x = s.combine(fa._1, xb._1)
  (x, xb._2)
}
```

FlatMap модифицирует правое значение,
а левое комбинирует по правилу из Semigroup. Для Tuple3 и более,
комбинирование осуществляется для всех кроме самого правого элемента

## Пример использования

В примере 2 вызова flatMap - оба на туплах `(Int, List[Long])`

Взял Long для примера, что бы не путать значения из листа и аккумулирующий Int.

```scala
import cats.syntax.all._
import scala.util.chaining.scalaUtilChainingOps
def doubleIfMod2(longs: List[Long]): (Int, List[Long]) =
  longs
    .map {
      case i if i % 2 == 0 => (1, i * 2)
      case i => (0, i)
    }
    .separate
    .leftMap(_.sum)

def changeSignForSmallNumbers(longs: List[Long]): (Int, List[Long]) =
  longs
    .map {
      case i if i < 5 => (1, -i)
      case i => (0, i)
    }
    .separate
    .leftMap(_.sum)

val list: List[Long] =
  (1, 2, 3, 4, 5).map(_.toLong).toList

(0, list)
  .flatMap(doubleIfMod2)
  .flatMap(changeSignForSmallNumbers)
  .tap(println)

```

Результат выполнения `(5,List(-1, -4, -3, 8, 5))`

* doubleIfMod2 - 2 модификации `(2 -> 4, 4 -> 8)`
* changeSignForSmallNumbers - 3 модификации `(1 -> -1, 4 -> -4, 3 -> -3)`

## Мысли

Увеличивает ли порог входа в проект использование подобных конструкций?
Скорее всего, читателю вашего кода придётся перейти в cats и почитать,
что же делает flatMap на tuple (Semigroup на левом значении - не очевидно).
Но, это лучше чем написать точно такой же велосипед самому.
Он будет таким же неочевидным, да еще и разным от проекта к проекту
