---
layout: post
title: "Мой workflow работы с claude"
date: 2025-07-06
categories:
  - scala
permalink: /project-copy-paste
---

# Copy-Paste workflow для работы с Claude и кодом проекта

Мой workflow для взаимодействия с Claude при разработке: два скрипта на Scala,
которые позволяют быстро передавать контекст проекта в Claude и получать обратно готовый код.

## Идея

`copy.scala` - собирает весь проект в один файл для Claude

`paste.scala` - восстанавливает файлы из ответа Claude прямо в проект

## Workflow

1. Подготовка контекста для Claude
    ```bash
    scala-cli copy.scala -- . output.txt
    ```
   
   Получаем файл output.txt со всем кодом проекта:

   ```
   // file: src/main/scala/Main.scala
   object Main:
     def main(args: Array[String]): Unit =
     println("Hello!")
   
   // file: build.sbt
   name := "my-project"
   scalaVersion := "3.6.4"
   ```

2. Работа с Claude

   Вставляем output.txt в `Project knowledge` проекта claude.

3. Настройка промпта для Claude
   
   Важно добавить промпт в claude проект `Set project instructions`:

   `При показе полных файлов из репозитория добавляй первой строкой комментарий // file: $path`

    claude будет отвечать в нужном формате

4. Применение изменений

   Копируем ответ Claude в буфер обмена и выполняем:

   ```
   clippaste | scala-cli run paste.scala
   ```
   
   Необходимые директории создаются автоматически
   
   ```
   Created file: src/main/scala/Main.scala
   Created file: build.sbt
   ```

   Готово! Все изменения применены к проекту.


## copy.scala

```scala
//> using scala "3.6.4-RC1"
//> using jvm "17"
//> using dep "org.eclipse.jgit:org.eclipse.jgit:7.1.0.202411261347-r"
//> using dep "org.slf4j:slf4j-simple:2.0.17"

import java.io.File
import java.io.PrintWriter
import java.nio.charset.*
import java.nio.file.*
import org.eclipse.jgit.ignore.FastIgnoreRule
import scala.jdk.CollectionConverters.*
import scala.util.Failure
import scala.util.Success
import scala.util.Try
import scala.util.Using

object Copy:
  type PathPredicate = Path => Boolean

  enum RuleType:
    case Include, Exclude

  case class FilterRule(ruleType: RuleType, predicate: PathPredicate)
  case class ReplacementRule(from: String, to: String)

  object PathFilters:
    def containsInPath(substring: String): PathPredicate =
      p => p.toString.toLowerCase.contains(substring.toLowerCase)

    def hasFileName(name: String): PathPredicate =
      p => p.getFileName.toString.equalsIgnoreCase(name)

    def hasExtension(ext: String): PathPredicate =
      p => p.toString.toLowerCase.endsWith(ext.toLowerCase)

    def hasAnyExtension(extensions: Set[String]): PathPredicate =
      p => {
        val lcPath = p.toString.toLowerCase
        extensions.exists(ext => lcPath.endsWith(ext))
      }

    def keepOnlyExtensions(extensions: Set[String]): FilterRule =
      exclude(not(hasAnyExtension(extensions)))

    def or(predicates: PathPredicate*): PathPredicate =
      p => predicates.exists(pred => pred(p))

    def and(predicates: PathPredicate*): PathPredicate =
      p => predicates.forall(pred => pred(p))

    def not(predicate: PathPredicate): PathPredicate =
      p => !predicate(p)

    def include(predicate: PathPredicate): FilterRule =
      FilterRule(RuleType.Include, predicate)

    def exclude(predicate: PathPredicate): FilterRule =
      FilterRule(RuleType.Exclude, predicate)

  def applyReplacements(
    text: String,
    replacements: List[ReplacementRule]
  ): String =
    replacements.foldLeft(text) { (acc, rule) =>
      acc.replace(rule.from, rule.to)
    }

  def loadGitignoreRules(basePath: String): List[FastIgnoreRule] =
    val gitignorePath = Paths.get(basePath, ".gitignore")
    if Files.exists(gitignorePath) then
      Files
        .readAllLines(gitignorePath)
        .asScala
        .filterNot(_.trim.isEmpty)
        .filterNot(_.startsWith("#"))
        .map(pattern => new FastIgnoreRule(pattern))
        .toList
    else List.empty

  def shouldIgnore(path: String, rules: List[FastIgnoreRule]): Boolean =
    path.contains("/.git/") ||
      path.startsWith(".git/") ||
      rules.exists(_.isMatch(path, false))

  def shouldIncludePath(path: Path, filterRules: List[FilterRule]): Boolean =
    if filterRules.isEmpty then return false

    var include = false
    for rule <- filterRules do
      if rule.predicate(path) then include = rule.ruleType == RuleType.Include

    include

  def findFiles(
    basePath: String,
    gitRules: List[FastIgnoreRule],
    filterRules: List[FilterRule]
  ): List[Path] =
    val basePathObj = Paths.get(basePath)

    Files
      .walk(basePathObj)
      .iterator
      .asScala
      .filter(Files.isRegularFile(_))
      .filter(p => shouldIncludePath(p, filterRules))
      .filterNot(p =>
        val relativePath = basePathObj.relativize(p).toString
        shouldIgnore(relativePath, gitRules)
      )
      .toList
      .sortBy(_.toString)

  def readFile(path: Path): String =
    val encodings = List(
      StandardCharsets.UTF_8,
      StandardCharsets.ISO_8859_1,
      Charset.forName("windows-1251")
    )

    def tryRead(encoding: Charset): Try[String] =
      Try(Files.readString(path, encoding))

    encodings
      .foldLeft[Option[String]](None) { (result, encoding) =>
        result.orElse {
          tryRead(encoding) match
            case Success(content) => Some(content)
            case Failure(_)       => None
        }
      }
      .getOrElse {
        System.err.println(
          s"Warning: Could not read file ${path.toString}. Skipping."
        )
        s"// Could not read file due to encoding issues"
      }

  def generateText(
    basePath: String,
    filterRules: List[FilterRule],
    replacements: List[ReplacementRule] = List.empty
  ): String =
    val gitRules = loadGitignoreRules(basePath)
    val files = findFiles(basePath, gitRules, filterRules)

    println(s"Selected ${files.size} files for processing:")
    files.foreach(f => println(s"- ${f.toString.replace(basePath + "/", "")}"))

    val fileContents = files
      .map { path =>
        val relativePath = path.toString.replace(basePath + "/", "")
        val processedPath = applyReplacements(relativePath, replacements)
        val rawContent = readFile(path)
        val processedContent = applyReplacements(rawContent, replacements)

        s"// file: $processedPath\n$processedContent"
      }
      .mkString("\n\n")

    fileContents

  @main def run(args: String*): Unit =
    println(s"args = ${args}")
    val basePath = args.headOption.getOrElse(".")
    val output = args.lift(1).getOrElse("project-knowledge.txt")

    println(s"Generating project knowledge from $basePath to $output")

    import PathFilters.*
    import RuleType.*

    val replacements = List[ReplacementRule](
      ReplacementRule("myprojectname", "example"),
      ReplacementRule("com.mycompany", "com.example"),
      ReplacementRule("MyProjectName", "ExampleProject")
    )

    val filterRules = List[FilterRule](
      include(p => true),
      exclude(hasFileName("copy.scala")),
      exclude(hasFileName("paste.scala")),
      include(containsInPath("shared/shared")),
      keepOnlyExtensions(Set(".scala", ".sbt", ".css", ".md", ".cfg", ".yml", ".j2")),
    )

    val buildFilesRules = List[FilterRule](
      include(p => true),
      keepOnlyExtensions(Set(".sbt")),
      include(and(hasFileName("build.properties"), containsInPath("project")))
    )

    val text = generateText(basePath, filterRules, replacements)

    Using(new PrintWriter(output)) { writer =>
      writer.write(text)
    }.get

    println(s"Project knowledge generated successfully to $output")

```

## Возможности copy.scala

- Фильтрация файлов - исключаем тесты, build артефакты
- Замена конфиденциальных данных - автоматически меняем название проекта, секретные ключи, пароли
- Учет .gitignore - не включаем игнорируемые файлы

```scala
val replacements = List(
  ReplacementRule("mycompany", "example"),
  ReplacementRule("secret-key", "demo-key")
)

val filterRules = List(
  exclude(containsInPath("target")),
  exclude(containsInPath("src/test")),
  keepOnlyExtensions(Set(".scala", ".sbt", ".md"))
)
```

## paste.scala

```scala
#!/usr/bin/env scala-cli

//> using scala "3.6.4"

import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import scala.collection.mutable.StringBuilder
import scala.io.StdIn

object Paste {
  case class ReplacementRule(from: String, to: String)

  private val FilePathPatterns = List(
    "//file:",
    "// file:",
    "//Файл:",
    "// Файл:",
    "-- file:",
    "-- Файл:",
    "# file:",
    "# Файл:",
    "<!-- file:",
    "<!-- Файл:",
    "/* file:",
    "/* Файл:"
  )

  def extractFilePath(line: String): Option[String] = {
    val trimmed = line.trim

    FilePathPatterns
      .find(pattern => trimmed.startsWith(pattern))
      .map { pattern =>
        val afterPattern = trimmed.substring(pattern.length)
        val cleanPath = if (pattern.startsWith("<!--")) {
          afterPattern.replaceAll("\\s*-->\\s*$", "")
        } else if (pattern.startsWith("/*")) {
           afterPattern.replaceAll("\\s*\\*/\\s*$", "")
        } else {
          afterPattern
        }
        cleanPath.trim
      }
  }

  def applyReplacements(
    text: String,
    replacements: List[ReplacementRule]
  ): String =
    replacements.foldLeft(text) { (acc, rule) =>
      acc.replace(rule.from, rule.to)
    }

  def writeFile(
    path: String,
    content: StringBuilder,
    replacements: List[ReplacementRule]
  ): Unit = {
    val processedPath = applyReplacements(path, replacements)
    val processedContent = applyReplacements(content.toString, replacements)

    val p = Paths.get(processedPath)

    Option(p.getParent).foreach(Files.createDirectories(_))

    Files.write(
      p,
      processedContent.getBytes,
      StandardOpenOption.CREATE,
      StandardOpenOption.TRUNCATE_EXISTING
    )
    println(s"Created file: $processedPath")
  }

  def main(args: Array[String]): Unit = {
    val replacements = List[ReplacementRule](
      ReplacementRule("myprojectname", "example"),
      ReplacementRule("com.mycompany", "com.example"),
      ReplacementRule("com/mycompany", "com/example"),
      ReplacementRule("MyProjectName", "ExampleProject")
    )

    var currentFilePath: Option[String] = None
    var currentContent = new StringBuilder

    var line = StdIn.readLine()
    while (line != null) {
      val filePath = extractFilePath(line)

      if (filePath.isDefined) {
        if (currentFilePath.isDefined) {
          writeFile(currentFilePath.get, currentContent, replacements)
          currentContent = new StringBuilder
        }

        currentFilePath = filePath
      } else if (currentFilePath.isDefined) {
        if (currentContent.nonEmpty) {
          currentContent.append("\n")
        }
        currentContent.append(line)
      }

      line = StdIn.readLine()
    }

    if (currentFilePath.isDefined) {
      writeFile(currentFilePath.get, currentContent, replacements)
    }
  }
}
```

## Предупреждение

`paste.scala` перезаписывает существующие файлы. Перед выполнением следует делать commit.
