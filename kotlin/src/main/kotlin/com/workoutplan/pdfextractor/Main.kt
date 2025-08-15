package com.workoutplan.pdfextractor

import org.apache.commons.cli.*
import org.yaml.snakeyaml.Yaml
import com.vladsch.flexmark.html.HtmlRenderer
import com.vladsch.flexmark.parser.Parser
import com.vladsch.flexmark.util.data.MutableDataSet
import com.vladsch.flexmark.ext.tables.TablesExtension
import java.io.IOException
import java.nio.file.*
import kotlin.system.exitProcess

class Config {
    var file: String = ""
    var output: String = ""
    var appendFirstPage: String = ""
    var pages: List<PageConfig> = emptyList()
}

class PageConfig {
    var name: String = ""
    var pageIndex: Int? = null
    var page: Int? = null
    var pageNumber: Int? = null
}

fun main(args: Array<String>) {
    val options = Options().apply {
        addOption("y", "yaml", true, "YAML file with page configuration")
        addOption("i", "input", true, "Input PDF file")
        addOption("o", "output", true, "Output PDF file")
        addOption("m", "markdown", true, "Markdown file to prepend")
    }

    val parser = DefaultParser()
    val formatter = HelpFormatter()

    try {
        val cmd = parser.parse(options, args)

        val yamlPath = cmd.getOptionValue("yaml", "../resources/config.yaml")
        val inputFile = cmd.getOptionValue("input")
        val outputFile = cmd.getOptionValue("output")
        val markdownFile = cmd.getOptionValue("markdown")

        extractPages(inputFile, outputFile, yamlPath, markdownFile)
    } catch (e: ParseException) {
        System.err.println("Error parsing command line: ${e.message}")
        formatter.printHelp("pdf-extractor", options)
        exitProcess(1)
    } catch (e: Exception) {
        System.err.println("Error: ${e.message}")
        e.printStackTrace()
        exitProcess(1)
    }
}

private fun markdownToPDFBytes(mdPath: String): ByteArray {
    val mdContent = Files.readString(Paths.get(mdPath))

    val options = MutableDataSet().apply {
        set(Parser.EXTENSIONS, listOf(TablesExtension.create()))
    }
    val parser = Parser.builder(options).build()
    val renderer = HtmlRenderer.builder(options).build()

    val document = parser.parse(mdContent)
    val htmlContent = renderer.render(document)

    val htmlTemplate = """
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
    """.trimIndent()

    val htmlFile = Files.createTempFile(null, ".html")
    val pdfFile = Files.createTempFile(null, ".pdf")

    return try {
        Files.writeString(htmlFile, htmlTemplate)

        val process = ProcessBuilder("node", "../puppeteer_render.js",
            htmlFile.toString(), pdfFile.toString()).start()
        val exitCode = process.waitFor()

        if (exitCode != 0) {
            throw IOException("Failed to convert HTML to PDF")
        }

        Files.readAllBytes(pdfFile)
    } finally {
        Files.deleteIfExists(htmlFile)
        Files.deleteIfExists(pdfFile)
    }
}

private fun extractPages(inputFile: String?, outputFile: String?, yamlPath: String, markdownFile: String?) {
    val configContent = Files.readString(Paths.get(yamlPath))
    val yaml = Yaml()
    val config = yaml.loadAs(configContent, Config::class.java)

    // Get project root (parent of yaml directory)
    val yamlParent = Paths.get(yamlPath).parent?.parent
        ?: throw IOException("Cannot determine project root from yaml path")

    val resolvedInputFile = when {
        !inputFile.isNullOrEmpty() -> inputFile
        config.file.isNotEmpty() && !Paths.get(config.file).isAbsolute -> {
            val standardPath = yamlParent.resolve(config.file)
            when {
                Files.exists(standardPath) -> standardPath.toString()
                else -> {
                    val fallbackPath = Paths.get(yamlPath).parent.resolve(config.file)
                    if (Files.exists(fallbackPath)) fallbackPath.toString() else standardPath.toString()
                }
            }
        }
        else -> config.file
    }

    val resolvedOutputFile = when {
        !outputFile.isNullOrEmpty() -> outputFile
        config.output.isNotEmpty() && !Paths.get(config.output).isAbsolute -> {
            val basePath = yamlParent.resolve(config.output)
            val path = Paths.get(basePath.toString())
            val fileName = path.fileName.toString()
            val dotIndex = fileName.lastIndexOf('.')
            val name = if (dotIndex > 0) fileName.substring(0, dotIndex) else fileName
            val ext = if (dotIndex > 0) fileName.substring(dotIndex) else ""
            path.parent.resolve("${name}_kotlin$ext").toString()
        }
        else -> {
            val path = Paths.get(config.output)
            val fileName = path.fileName.toString()
            val dotIndex = fileName.lastIndexOf('.')
            val name = if (dotIndex > 0) fileName.substring(0, dotIndex) else fileName
            val ext = if (dotIndex > 0) fileName.substring(dotIndex) else ""
            path.parent.resolve("${name}_kotlin$ext").toString()
        }
    }

    val mdFile = when {
        !markdownFile.isNullOrEmpty() -> markdownFile
        config.appendFirstPage.isNotEmpty() -> {
            Paths.get(yamlPath).parent.resolve(config.appendFirstPage).toString()
        }
        else -> null
    }

    if (!Files.exists(Paths.get(resolvedInputFile))) {
        println("Error: '$resolvedInputFile' not found.")
        return
    }

    // Collect selected pages
    val selectedPages = config.pages
        .mapNotNull { it.pageIndex ?: it.page }
        .distinct()

    // Create temporary directory
    val tempDir = Files.createTempDirectory("pdf-extractor")
    val filesToMerge = mutableListOf<String>()

    try {
        // Add markdown PDF if provided
        mdFile?.let { md ->
            val mdPDFBytes = markdownToPDFBytes(md)
            val mdPDFPath = tempDir.resolve("markdown.pdf")
            Files.write(mdPDFPath, mdPDFBytes)
            filesToMerge.add(mdPDFPath.toString())
        }

        // Extract specified pages using pdftk
        if (selectedPages.isNotEmpty()) {
            val extractedPDF = tempDir.resolve("extracted.pdf")

            val args = listOf("pdftk", resolvedInputFile, "cat") +
                      selectedPages.map { it.toString() } +
                      listOf("output", extractedPDF.toString())

            val process = ProcessBuilder(args).start()
            val exitCode = process.waitFor()

            if (exitCode != 0) {
                throw IOException("Failed to extract pages with pdftk")
            }

            filesToMerge.add(extractedPDF.toString())
        }

        // Merge all PDFs
        when (filesToMerge.size) {
            1 -> {
                // Just copy the single file
                Files.copy(Paths.get(filesToMerge[0]), Paths.get(resolvedOutputFile),
                          StandardCopyOption.REPLACE_EXISTING)
            }
            in 2..Int.MAX_VALUE -> {
                // Merge multiple files
                val args = listOf("pdftk") + filesToMerge + listOf("cat", "output", resolvedOutputFile)

                val process = ProcessBuilder(args).start()
                val exitCode = process.waitFor()

                if (exitCode != 0) {
                    throw IOException("Failed to merge PDFs with pdftk")
                }
            }
        }

        println("Saved to: $resolvedOutputFile")

    } finally {
        // Clean up temporary directory
        Files.walk(tempDir)
            .sorted(Comparator.reverseOrder())
            .forEach { Files.deleteIfExists(it) }
    }
}
