import java.io.{File, FileWriter, IOException}
import java.nio.file.{Files, Path, Paths}
import scala.io.Source
import scala.sys.process._
import scala.util.{Try, Using}
import scopt.OptionParser
import io.circe.yaml.parser
import io.circe.generic.auto._
import com.vladsch.flexmark.html.HtmlRenderer
import com.vladsch.flexmark.parser.Parser
import com.vladsch.flexmark.ext.tables.TablesExtension
import com.vladsch.flexmark.util.data.MutableDataSet
import java.util.Collections

case class PageConfig(
  name: String,
  pageIndex: Option[Int] = None,
  page: Option[Int] = None,
  pageNumber: Option[Int] = None
)

case class Config(
  file: Option[String] = None,
  output: Option[String] = None,
  appendFirstPage: Option[String] = None,
  pages: List[PageConfig] = List.empty
)

case class CliArgs(
  yaml: String = "../resources/config.yaml",
  input: String = "",
  output: String = "",
  markdown: String = ""
)

object PdfExtractor {

  def markdownToPdfBytes(mdPath: String): Array[Byte] = {
    val mdContent = Using(Source.fromFile(mdPath))(_.mkString).get

    // Configure Flexmark with table support
    val options = new MutableDataSet()
    options.set(Parser.EXTENSIONS, Collections.singletonList(TablesExtension.create()).asInstanceOf[java.util.Collection[com.vladsch.flexmark.util.misc.Extension]])

    val parser = Parser.builder(options).build()
    val renderer = HtmlRenderer.builder(options).build()
    val document = parser.parse(mdContent)
    val htmlContent = renderer.render(document)

    val htmlTemplate = s"""
      <html>
      <head>
          <style>
              body { font-family: Helvetica, Arial, sans-serif; margin: 2em; }
              h1, h2, h3, h4 { color: #2a4d7c; }
              table { border-collapse: collapse; width: 100%; margin-bottom: 1em; }
              th, td { border: 1px solid #888; padding: 0.5em; text-align: left; }
              th { background: #d5e4f3; }
              code { background: #eee; padding: 2px 4px; border-radius: 4px; }
              pre { background: #f4f4f4; padding: 1em; border-radius: 4px; }
              ul { margin: 1em 0; padding-left: 2em; }
              li { margin: 0.5em 0; }
          </style>
      </head>
      <body>$htmlContent</body>
      </html>
    """

    val htmlFile = Files.createTempFile("", ".html")
    val pdfFile = Files.createTempFile("", ".pdf")

    try {
      Files.write(htmlFile, htmlTemplate.getBytes)
      val cmd = Seq("node", "../puppeteer_render.js", htmlFile.toString, pdfFile.toString)
      val result = cmd.!
      if (result != 0) {
        throw new IOException(s"Failed to convert markdown to PDF: $result")
      }
      Files.readAllBytes(pdfFile)
    } finally {
      Files.deleteIfExists(htmlFile)
      Files.deleteIfExists(pdfFile)
    }
  }

  def extractPages(inputPdf: String, outputPdf: String, yamlPath: String, mdPath: Option[String] = None): Unit = {
    val configContent = Using(Source.fromFile(yamlPath))(_.mkString).get
    val config = io.circe.yaml.parser.parse(configContent).flatMap(_.as[Config]).getOrElse(Config())

    val selectedPages = config.pages
      .flatMap(pageConfig => pageConfig.pageIndex.orElse(pageConfig.page))
      .distinct

    val tempDir = Files.createTempDirectory("pdf-extractor")

    try {
      val filesToMerge = scala.collection.mutable.ListBuffer[String]()

      // Add markdown PDF if provided
      val finalMdPath = mdPath.orElse {
        config.appendFirstPage.map { appendFile =>
          Paths.get(yamlPath).getParent.resolve(appendFile).toString
        }
      }

      finalMdPath.foreach { mdFile =>
        if (Files.exists(Paths.get(mdFile))) {
          val mdPdfBytes = markdownToPdfBytes(mdFile)
          val mdPdfPath = tempDir.resolve("markdown.pdf")
          Files.write(mdPdfPath, mdPdfBytes)
          filesToMerge += mdPdfPath.toString
        }
      }

      // Extract specified pages using pdftk
      if (selectedPages.nonEmpty) {
        val extractedPdf = tempDir.resolve("extracted.pdf").toString
        val pagesStr = selectedPages.map(_.toString)
        val cmd = Seq("pdftk", inputPdf, "cat") ++ pagesStr ++ Seq("output", extractedPdf)
        val result = cmd.!
        if (result != 0) {
          throw new IOException(s"Failed to extract pages with pdftk: $result")
        }
        filesToMerge += extractedPdf
      }

      // Merge all PDFs
      filesToMerge.toList match {
        case singleFile :: Nil =>
          Files.copy(Paths.get(singleFile), Paths.get(outputPdf))
        case multipleFiles if multipleFiles.length > 1 =>
          val cmd = Seq("pdftk") ++ multipleFiles ++ Seq("cat", "output", outputPdf)
          val result = cmd.!
          if (result != 0) {
            throw new IOException(s"Failed to merge PDFs with pdftk: $result")
          }
        case _ =>
          throw new IllegalStateException("No files to process")
      }

      println(s"Saved to: $outputPdf")
    } finally {
      // Clean up temporary directory
      def deleteRecursively(file: File): Unit = {
        if (file.isDirectory) {
          file.listFiles.foreach(deleteRecursively)
        }
        file.delete()
      }
      deleteRecursively(tempDir.toFile)
    }
  }

  def main(args: Array[String]): Unit = {
    val parser = new OptionParser[CliArgs]("pdf-extractor") {
      head("pdf-extractor", "1.0")
      help("help").text("Extract selected pages from PDF and optionally prepend Markdown intro")

      opt[String]('y', "yaml")
        .action((x, c) => c.copy(yaml = x))
        .text("YAML file with page configuration")

      opt[String]('i', "input")
        .action((x, c) => c.copy(input = x))
        .text("Input PDF file")

      opt[String]('o', "output")
        .action((x, c) => c.copy(output = x))
        .text("Output PDF file")

      opt[String]('m', "markdown")
        .action((x, c) => c.copy(markdown = x))
        .text("Markdown file to prepend")
    }

    parser.parse(args, CliArgs()) match {
      case Some(cliArgs) =>
        try {
          val configContent = Using(Source.fromFile(cliArgs.yaml))(_.mkString).get
          val config = io.circe.yaml.parser.parse(configContent).flatMap(_.as[Config]).getOrElse(Config())

          // Get project root (parent of yaml directory)
          val yamlParent = Paths.get(cliArgs.yaml).getParent.getParent

          val inputFile = if (cliArgs.input.nonEmpty) {
            cliArgs.input
          } else {
            config.file.map { file =>
              if (Paths.get(file).isAbsolute) {
                file
              } else {
                val standardPath = yamlParent.resolve(file)
                if (Files.exists(standardPath)) {
                  standardPath.toString
                } else {
                  val fallbackPath = Paths.get(cliArgs.yaml).getParent.resolve(file)
                  if (Files.exists(fallbackPath)) {
                    fallbackPath.toString
                  } else {
                    standardPath.toString
                  }
                }
              }
            }.getOrElse("")
          }

          val outputFile = if (cliArgs.output.nonEmpty) {
            cliArgs.output
          } else {
            config.output.map { out =>
              val basePath = if (Paths.get(out).isAbsolute) {
                Paths.get(out)
              } else {
                yamlParent.resolve(out)
              }

              // Add _scala suffix to filename
              val fileName = basePath.getFileName.toString
              val dotIndex = fileName.lastIndexOf('.')
              val (name, ext) = if (dotIndex > 0) {
                (fileName.substring(0, dotIndex), fileName.substring(dotIndex))
              } else {
                (fileName, "")
              }
              basePath.getParent.resolve(s"${name}_scala$ext").toString
            }.getOrElse("")
          }

          val markdownFile = if (cliArgs.markdown.nonEmpty) Some(cliArgs.markdown) else None

          if (!Files.exists(Paths.get(inputFile))) {
            println(s"Error: '$inputFile' not found.")
            System.exit(1)
          }

          extractPages(inputFile, outputFile, cliArgs.yaml, markdownFile)
        } catch {
          case e: Exception =>
            println(s"Error: ${e.getMessage}")
            System.exit(1)
        }
      case None =>
        System.exit(1)
    }
  }
}
