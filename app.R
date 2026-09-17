# app.R
# ============================================================
# GEO Sample–Expression Matrix Explorer + Interactive PCA
# ============================================================
# Adds:
#   - interactive Plotly PCA
#   - zoom / pan / hover / legend toggling
#   - plot title, point size, opacity, label controls
#   - PC-axis selector
#   - colour-by metadata/group
#   - optional shape-by group/metadata
#   - SVG, JPEG and PNG export using the same plot settings
#
# No DEG or ML is included yet.
# ============================================================

library(shiny)
library(GEOquery)
library(DT)
library(AnnotationDbi)
library(ggplot2)
library(plotly)

source(file.path("R", "helpers.R"))

ui <- fluidPage(

  tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "styles.css"
    )
  ),

  titlePanel("GEOPrism | A clearer view of gene expression.", windowTitle = "GEOPrism"),

  sidebarLayout(

    sidebarPanel(

      textInput(
        "gse_id",
        "GEO Series accession:",
        value = "GSE9624"
      ),

      actionButton(
        "load_gse",
        "Load GEO dataset",
        class = "btn-primary"
      ),

      hr(),
      uiOutput("platform_ui"),
      uiOutput("sample_ui"),

      hr(),
      uiOutput("metadata_column_ui"),

      hr(),

      radioButtons(
        "orientation",
        "Expression-matrix orientation:",
        choices = c(
          "Features / genes as rows" = "feature_rows",
          "Samples as rows" = "sample_rows"
        ),
        selected = "feature_rows"
      ),

      numericInput(
        "n_preview",
        "Rows to preview:",
        value = 20,
        min = 5,
        max = 500,
        step = 5
      ),

      hr(),
      uiOutput("collapse_ui"),

      hr(),

      downloadButton(
        "download_combined",
        "Download ML-ready table"
      ),

      br(), br(),

      downloadButton(
        "download_gene_matrix",
        "Download gene matrix"
      ),

      br(), br(),

      downloadButton(
        "download_metadata",
        "Download sample metadata"
      )
    ),

    mainPanel(

      tabsetPanel(

        tabPanel(
          "1. Dataset summary",
          br(),
          verbatimTextOutput("dataset_summary")
        ),

        tabPanel(
          "2. Sample metadata",
          br(),
          DTOutput("metadata_table")
        ),

        tabPanel(
          "3. Feature matrix",
          br(),
          DTOutput("feature_expression_table")
        ),

        tabPanel(
          "4. Probe → gene mapping",
          br(),
          verbatimTextOutput("mapping_summary"),
          br(),
          DTOutput("mapping_table")
        ),

        tabPanel(
          "5. Gene matrix",
          br(),

          textInput(
            "gene_search",
            "Optional gene-symbol filter:",
            value = "",
            placeholder = "APOB, BUB1, CDC20"
          ),

          DTOutput("gene_expression_table")
        ),

        tabPanel(
          "6. Define sample groups",
          br(),

          p(
            strong("Optional standardization step: "),
            "GEO metadata may already state disease status. ",
            "This Group column simply gives you one clean label for later analyses."
          ),

          actionButton(
            "reset_groups",
            "Reset groups"
          ),

          br(), br(),

          DTOutput("group_assignment_table")
        ),

        tabPanel(
          "7. Combined ML-ready table",
          br(),
          DTOutput("combined_table")
        ),

        tabPanel(
          "8. Interactive PCA",
          br(),

          fluidRow(

            column(
              width = 3,

              wellPanel(
                h4("PCA calculation"),

                selectInput(
                  "pca_feature_mode",
                  "Genes to use:",
                  choices = c(
                    "All variable mapped genes" = "all",
                    "Top variable genes" = "top"
                  ),
                  selected = "top"
                ),

                conditionalPanel(
                  condition = "input.pca_feature_mode == 'top'",
                  numericInput(
                    "pca_top_n",
                    "Number of variable genes:",
                    value = 1000,
                    min = 50,
                    step = 50
                  )
                ),

                checkboxInput(
                  "pca_center",
                  "Center genes",
                  value = TRUE
                ),

                checkboxInput(
                  "pca_scale",
                  "Scale genes to unit variance",
                  value = FALSE
                ),

                checkboxInput(
                  "pca_drop_excluded",
                  "Remove samples labelled Exclude",
                  value = TRUE
                )
              ),

              wellPanel(
                h4("Axes"),

                uiOutput("pca_axis_ui")
              )
            ),

            column(
              width = 3,

              wellPanel(
                h4("Appearance"),

                textInput(
                  "pca_title",
                  "Plot title:",
                  value = "PCA of gene-expression samples"
                ),

                uiOutput("pca_colour_ui"),

                uiOutput("pca_shape_ui"),

                sliderInput(
                  "pca_point_size",
                  "Point size:",
                  min = 4,
                  max = 18,
                  value = 9,
                  step = 1
                ),

                sliderInput(
                  "pca_opacity",
                  "Point opacity:",
                  min = 0.2,
                  max = 1,
                  value = 0.9,
                  step = 0.1
                ),

                selectInput(
                  "pca_label_mode",
                  "Sample labels:",
                  choices = c(
                    "Hover only" = "hover",
                    "Always show" = "always",
                    "No labels" = "none"
                  ),
                  selected = "hover"
                ),

                checkboxInput(
                  "pca_show_legend",
                  "Show legend",
                  value = TRUE
                )
              )
            ),

            column(
              width = 6,

              wellPanel(
                strong("Interactive controls: "),
                "hover over samples, drag to zoom, double-click to reset, ",
                "pan, box-select, lasso-select, and click legend entries to hide/show groups."
              ),

              plotlyOutput(
                "pca_plotly",
                height = "600px"
              ),

              fluidRow(
                column(
                  3,
                  downloadButton(
                    "download_pca_svg",
                    "Export SVG"
                  )
                ),
                column(
                  3,
                  downloadButton(
                    "download_pca_jpeg",
                    "Export JPG"
                  )
                ),
                column(
                  3,
                  downloadButton(
                    "download_pca_png",
                    "Export PNG"
                  )
                ),
                column(
                  3,
                  downloadButton(
                    "download_pca_scores",
                    "PCA coordinates"
                  )
                )
              )
            )
          ),

          hr(),

          fluidRow(

            column(
              width = 6,
              h4("Interactive explained variance"),
              plotlyOutput(
                "scree_plotly",
                height = "380px"
              )
            ),

            column(
              width = 6,
              h4("PCA summary"),
              verbatimTextOutput("pca_summary")
            )
          ),

          hr(),

          h4("PCA sample coordinates"),
          DTOutput("pca_scores_table")
        )
      )
    )
  )
)

server <- function(input, output, session) {

  # ----------------------------------------------------------
  # GEO
  # ----------------------------------------------------------
  gse_list <- eventReactive(input$load_gse, {
    req(input$gse_id)

    gse_id <- toupper(trimws(input$gse_id))

    validate(
      need(
        grepl("^GSE[0-9]+$", gse_id),
        "Enter a valid GEO Series accession, e.g. GSE9624."
      )
    )

    withProgress(
      message = paste("Downloading", gse_id, "from GEO..."),
      value = 0.1,
      {
        obj <- getGEO(
          gse_id,
          GSEMatrix = TRUE,
          AnnotGPL = FALSE
        )

        incProgress(0.9)
        obj
      }
    )
  })

  output$platform_ui <- renderUI({
    obj <- gse_list()
    req(obj)

    platform_names <- sapply(
      obj,
      function(eset) annotation(eset)
    )

    labels <- paste0(seq_along(obj), ": ", platform_names)

    selectInput(
      "platform_index",
      "Platform / ExpressionSet:",
      choices = setNames(seq_along(obj), labels),
      selected = 1
    )
  })

  eset <- reactive({
    obj <- gse_list()
    req(obj, input$platform_index)
    obj[[as.integer(input$platform_index)]]
  })

  # ----------------------------------------------------------
  # Metadata
  # ----------------------------------------------------------
  sample_metadata <- reactive({
    e <- eset()
    pheno <- pData(e)

    out <- data.frame(
      Sample_ID = rownames(pheno),
      pheno,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )

    rownames(out) <- NULL
    out
  })

  output$sample_ui <- renderUI({
    meta <- sample_metadata()

    if ("title" %in% colnames(meta)) {
      labels <- paste0(meta$Sample_ID, " | ", meta$title)
    } else {
      labels <- meta$Sample_ID
    }

    checkboxGroupInput(
      "selected_samples",
      "Samples to include:",
      choices = setNames(meta$Sample_ID, labels),
      selected = meta$Sample_ID
    )
  })

  output$metadata_column_ui <- renderUI({
    meta <- sample_metadata()

    selectizeInput(
      "metadata_columns",
      "Metadata to append:",
      choices = setdiff(colnames(meta), "Sample_ID"),
      selected = default_metadata_columns(meta),
      multiple = TRUE,
      options = list(plugins = list("remove_button"))
    )
  })

  # ----------------------------------------------------------
  # Feature matrix
  # ----------------------------------------------------------
  feature_matrix <- reactive({
    e <- eset()
    req(input$selected_samples)

    mat <- exprs(e)

    keep_samples <- intersect(
      input$selected_samples,
      colnames(mat)
    )

    validate(
      need(length(keep_samples) >= 2, "Select at least two samples.")
    )

    mat[, keep_samples, drop = FALSE]
  })

  # ----------------------------------------------------------
  # Probe-to-gene mapping
  # ----------------------------------------------------------
  mapping_info <- reactive({
    e <- eset()

    platform_name <- annotation(e)
    pkg <- annotation_package_for(platform_name)

    if (is.null(pkg)) {
      return(
        list(
          ok = FALSE,
          package = NA_character_,
          platform = platform_name,
          message = paste0(
            "No built-in annotation mapping configured for ",
            platform_name,
            "."
          ),
          mapping = NULL
        )
      )
    }

    if (!requireNamespace(pkg, quietly = TRUE)) {
      return(
        list(
          ok = FALSE,
          package = pkg,
          platform = platform_name,
          message = paste0(
            "Annotation package '",
            pkg,
            "' is not installed. Run install_packages.R."
          ),
          mapping = NULL
        )
      )
    }

    mat <- exprs(e)
    feature_ids <- rownames(mat)
    db <- getExportedValue(pkg, pkg)

    symbols <- AnnotationDbi::mapIds(
      db,
      keys = feature_ids,
      column = "SYMBOL",
      keytype = "PROBEID",
      multiVals = "first"
    )

    mapping <- data.frame(
      Feature_ID = feature_ids,
      Gene_Symbol = unname(symbols),
      stringsAsFactors = FALSE
    )

    mapping$Mapped <- !is.na(mapping$Gene_Symbol) &
      nzchar(mapping$Gene_Symbol)

    mapped_symbols <- mapping$Gene_Symbol[mapping$Mapped]

    list(
      ok = TRUE,
      package = pkg,
      platform = platform_name,
      message = "Mapping completed successfully.",
      mapping = mapping,
      total_features = nrow(mapping),
      mapped_features = sum(mapping$Mapped),
      unmapped_features = sum(!mapping$Mapped),
      unique_genes = length(unique(mapped_symbols)),
      duplicate_mapped_features =
        sum(mapping$Mapped) - length(unique(mapped_symbols))
    )
  })

  output$collapse_ui <- renderUI({
    info <- mapping_info()

    if (!isTRUE(info$ok)) {
      return(
        helpText(
          "Gene-level options require a supported annotation package."
        )
      )
    }

    radioButtons(
      "collapse_mode",
      "If multiple probes map to one gene:",
      choices = c(
        "Average into one gene row" = "average",
        "Keep mapped probes separately" = "keep"
      ),
      selected = "average"
    )
  })

  gene_matrix <- reactive({
    info <- mapping_info()

    validate(
      need(isTRUE(info$ok), info$message)
    )

    req(input$collapse_mode)

    mat <- feature_matrix()
    map <- info$mapping

    idx <- match(rownames(mat), map$Feature_ID)
    symbols <- map$Gene_Symbol[idx]

    keep <- !is.na(symbols) & nzchar(symbols)

    mat_mapped <- mat[keep, , drop = FALSE]
    symbols_mapped <- symbols[keep]
    feature_ids_mapped <- rownames(mat_mapped)

    if (input$collapse_mode == "average") {

      summed <- rowsum(
        mat_mapped,
        group = symbols_mapped,
        reorder = FALSE
      )

      probe_counts <- as.numeric(
        table(
          factor(
            symbols_mapped,
            levels = rownames(summed)
          )
        )
      )

      gene_mat <- sweep(
        summed,
        MARGIN = 1,
        STATS = probe_counts,
        FUN = "/"
      )

      rownames(gene_mat) <- rownames(summed)

    } else {

      gene_mat <- mat_mapped

      rownames(gene_mat) <- make.unique(
        paste0(
          symbols_mapped,
          " | ",
          feature_ids_mapped
        )
      )
    }

    gene_mat
  })

  # ----------------------------------------------------------
  # Group assignment
  # ----------------------------------------------------------
  group_assignments <- reactiveVal(
    data.frame(
      Sample_ID = character(),
      Group = character(),
      stringsAsFactors = FALSE
    )
  )

  observeEvent(
    list(eset(), input$selected_samples),
    {
      req(input$selected_samples)

      old <- group_assignments()

      new <- data.frame(
        Sample_ID = input$selected_samples,
        Group = "Unassigned",
        stringsAsFactors = FALSE
      )

      if (nrow(old) > 0) {
        m <- match(new$Sample_ID, old$Sample_ID)
        found <- !is.na(m)
        new$Group[found] <- old$Group[m[found]]
      }

      group_assignments(new)
    },
    ignoreInit = TRUE
  )

  observeEvent(input$reset_groups, {
    req(input$selected_samples)

    group_assignments(
      data.frame(
        Sample_ID = input$selected_samples,
        Group = "Unassigned",
        stringsAsFactors = FALSE
      )
    )
  })

  group_assignment_display <- reactive({
    meta <- sample_metadata()
    groups <- group_assignments()

    req(nrow(groups) > 0)

    chosen_meta <- intersect(
      input$metadata_columns,
      colnames(meta)
    )

    meta_small <- meta[
      match(groups$Sample_ID, meta$Sample_ID),
      c("Sample_ID", chosen_meta),
      drop = FALSE
    ]

    out <- data.frame(
      Sample_ID = groups$Sample_ID,
      Group = groups$Group,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    if (length(chosen_meta) > 0) {
      out <- data.frame(
        out,
        meta_small[, chosen_meta, drop = FALSE],
        check.names = FALSE
      )
    }

    out
  })

  output$group_assignment_table <- renderDT({
    dat <- group_assignment_display()

    disabled_cols <- c(
      0,
      if (ncol(dat) > 2) 2:(ncol(dat) - 1) else integer(0)
    )

    datatable(
      dat,
      editable = list(
        target = "cell",
        disable = list(columns = disabled_cols)
      ),
      rownames = FALSE,
      filter = "top",
      options = list(
        scrollX = TRUE,
        pageLength = 15
      )
    )
  })

  observeEvent(
    input$group_assignment_table_cell_edit,
    {
      edit <- input$group_assignment_table_cell_edit

      if (edit$col == 1) {
        display_now <- group_assignment_display()

        sample_id <- display_now$Sample_ID[edit$row]
        new_group <- clean_group_label(edit$value)

        groups <- group_assignments()
        idx <- match(sample_id, groups$Sample_ID)

        if (!is.na(idx)) {
          groups$Group[idx] <- new_group
          group_assignments(groups)
        }
      }
    }
  )

  # ----------------------------------------------------------
  # Combined table
  # ----------------------------------------------------------
  combined_ml_table <- reactive({
    mat <- gene_matrix()
    groups <- group_assignments()
    meta <- sample_metadata()

    req(nrow(groups) > 0)

    gene_df <- as.data.frame(
      t(mat),
      check.names = FALSE
    )

    gene_df <- data.frame(
      Sample_ID = rownames(gene_df),
      gene_df,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )

    gene_df <- gene_df[
      match(groups$Sample_ID, gene_df$Sample_ID),
      ,
      drop = FALSE
    ]

    chosen_meta <- intersect(
      input$metadata_columns,
      colnames(meta)
    )

    meta_small <- meta[
      match(groups$Sample_ID, meta$Sample_ID),
      c("Sample_ID", chosen_meta),
      drop = FALSE
    ]

    out <- data.frame(
      Sample_ID = groups$Sample_ID,
      Group = groups$Group,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    if (length(chosen_meta) > 0) {
      out <- data.frame(
        out,
        meta_small[, chosen_meta, drop = FALSE],
        check.names = FALSE
      )
    }

    gene_only <- gene_df[
      ,
      setdiff(colnames(gene_df), "Sample_ID"),
      drop = FALSE
    ]

    data.frame(
      out,
      gene_only,
      check.names = FALSE
    )
  })

  # ----------------------------------------------------------
  # PCA
  # ----------------------------------------------------------
  pca_input <- reactive({
    mat <- gene_matrix()
    groups <- group_assignments()

    validate(
      need(ncol(mat) >= 3, "PCA needs at least three samples.")
    )

    if (isTRUE(input$pca_drop_excluded) && nrow(groups) > 0) {
      lookup <- setNames(groups$Group, groups$Sample_ID)

      keep <- is.na(lookup[colnames(mat)]) |
        toupper(lookup[colnames(mat)]) != "EXCLUDE"

      mat <- mat[, keep, drop = FALSE]
    }

    validate(
      need(ncol(mat) >= 3, "Fewer than three samples remain.")
    )

    finite_rows <- apply(
      mat,
      1,
      function(x) all(is.finite(x))
    )

    mat <- mat[finite_rows, , drop = FALSE]

    vars <- safe_variance(mat)
    keep_var <- is.finite(vars) & vars > 0

    mat <- mat[keep_var, , drop = FALSE]
    vars <- vars[keep_var]

    validate(
      need(nrow(mat) >= 2, "Too few variable genes remain.")
    )

    if (identical(input$pca_feature_mode, "top")) {

      top_n <- min(
        as.integer(input$pca_top_n),
        nrow(mat)
      )

      ord <- order(
        vars,
        decreasing = TRUE
      )[seq_len(top_n)]

      mat <- mat[ord, , drop = FALSE]
    }

    mat
  })

  pca_result <- reactive({
    mat <- pca_input()

    fit <- prcomp(
      t(mat),
      center = isTRUE(input$pca_center),
      scale. = isTRUE(input$pca_scale)
    )

    variance_pct <- 100 * (
      fit$sdev^2 / sum(fit$sdev^2)
    )

    list(
      fit = fit,
      variance_pct = variance_pct,
      genes_used = nrow(mat),
      samples_used = ncol(mat)
    )
  })

  output$pca_axis_ui <- renderUI({
    result <- pca_result()

    pcs <- paste0(
      "PC",
      seq_len(ncol(result$fit$x))
    )

    tagList(
      selectInput(
        "pca_x_pc",
        "X axis:",
        choices = pcs,
        selected = "PC1"
      ),

      selectInput(
        "pca_y_pc",
        "Y axis:",
        choices = pcs,
        selected = if ("PC2" %in% pcs) "PC2" else pcs[1]
      )
    )
  })

  output$pca_colour_ui <- renderUI({
    meta <- sample_metadata()

    selectInput(
      "pca_colour_by",
      "Colour by:",
      choices = c(
        "Assigned Group" = ".Group",
        setdiff(colnames(meta), "Sample_ID")
      ),
      selected = ".Group"
    )
  })

  output$pca_shape_ui <- renderUI({
    meta <- sample_metadata()

    selectInput(
      "pca_shape_by",
      "Point shape by:",
      choices = c(
        "None" = ".None",
        "Assigned Group" = ".Group",
        setdiff(colnames(meta), "Sample_ID")
      ),
      selected = ".None"
    )
  })

  pca_scores <- reactive({
    result <- pca_result()
    fit <- result$fit

    scores <- as.data.frame(
      fit$x,
      check.names = FALSE
    )

    scores$Sample_ID <- rownames(scores)

    scores <- scores[
      ,
      c(
        "Sample_ID",
        setdiff(colnames(scores), "Sample_ID")
      ),
      drop = FALSE
    ]

    meta <- sample_metadata()
    groups <- group_assignments()

    group_lookup <- setNames(
      groups$Group,
      groups$Sample_ID
    )

    scores$Group <- unname(
      group_lookup[scores$Sample_ID]
    )

    scores$Group[
      is.na(scores$Group) |
      !nzchar(scores$Group)
    ] <- "Unassigned"

    meta_rows <- meta[
      match(scores$Sample_ID, meta$Sample_ID),
      ,
      drop = FALSE
    ]

    if (!is.null(input$pca_colour_by) &&
        input$pca_colour_by != ".Group" &&
        input$pca_colour_by %in% colnames(meta_rows)) {

      scores$ColourVariable <- as.character(
        meta_rows[[input$pca_colour_by]]
      )

    } else {

      scores$ColourVariable <- scores$Group
    }

    scores$ColourVariable[
      is.na(scores$ColourVariable) |
      !nzchar(scores$ColourVariable)
    ] <- "Missing"

    if (!is.null(input$pca_shape_by) &&
        input$pca_shape_by == ".Group") {

      scores$ShapeVariable <- scores$Group

    } else if (
      !is.null(input$pca_shape_by) &&
      input$pca_shape_by != ".None" &&
      input$pca_shape_by %in% colnames(meta_rows)
    ) {

      scores$ShapeVariable <- as.character(
        meta_rows[[input$pca_shape_by]]
      )

    } else {

      scores$ShapeVariable <- "All samples"
    }

    scores$ShapeVariable[
      is.na(scores$ShapeVariable) |
      !nzchar(scores$ShapeVariable)
    ] <- "Missing"

    # Helpful hover metadata
    if ("title" %in% colnames(meta_rows)) {
      scores$Title <- as.character(meta_rows$title)
    } else {
      scores$Title <- ""
    }

    scores
  })

  # Reusable static ggplot; Plotly and image exports both use it.
  pca_ggplot <- reactive({
    result <- pca_result()
    scores <- pca_scores()

    req(input$pca_x_pc, input$pca_y_pc)

    xpc <- input$pca_x_pc
    ypc <- input$pca_y_pc

    validate(
      need(
        nzchar(xpc) && nzchar(ypc),
        "Choose PCA axes before drawing the plot."
      )
    )

    validate(
      need(xpc != ypc, "Choose different PCs for X and Y axes.")
    )

    pc_names <- colnames(result$fit$x)

    xi <- match(xpc, pc_names)
    yi <- match(ypc, pc_names)

    v <- result$variance_pct

    scores$X <- scores[[xpc]]
    scores$Y <- scores[[ypc]]

    scores$HoverText <- paste0(
      "Sample: ", scores$Sample_ID,
      "<br>Group: ", scores$Group,
      ifelse(
        nzchar(scores$Title),
        paste0("<br>Title: ", scores$Title),
        ""
      ),
      "<br>", xpc, ": ", round(scores$X, 3),
      "<br>", ypc, ": ", round(scores$Y, 3)
    )

    if (input$pca_shape_by == ".None") {
      p <- ggplot(
        scores,
        aes(
          x = X,
          y = Y,
          colour = ColourVariable,
          text = HoverText
        )
      ) +
        geom_point(
          size = input$pca_point_size / 2.5,
          alpha = input$pca_opacity
        )
    } else {
      p <- ggplot(
        scores,
        aes(
          x = X,
          y = Y,
          colour = ColourVariable,
          shape = ShapeVariable,
          text = HoverText
        )
      ) +
        geom_point(
          size = input$pca_point_size / 2.5,
          alpha = input$pca_opacity
        )
    }

    if (identical(input$pca_label_mode, "always")) {
      p <- p +
        geom_text(
          aes(label = Sample_ID),
          vjust = -0.8,
          size = 3,
          show.legend = FALSE
        )
    }

    # Do not use ifelse(..., NULL, ...) here.
    # ifelse() with NULL can produce a zero-length value and trigger:
    # "replacement has length zero" when Plotly/ggplot processes labels.
    colour_label <- if (
      identical(input$pca_colour_by, ".Group")
    ) {
      "Group"
    } else {
      input$pca_colour_by
    }

    shape_label <- NULL

    if (!is.null(input$pca_shape_by) &&
        !identical(input$pca_shape_by, ".None")) {

      shape_label <- if (
        identical(input$pca_shape_by, ".Group")
      ) {
        "Group"
      } else {
        input$pca_shape_by
      }
    }

    p <- p +
      labs(
        title = input$pca_title,
        x = paste0(
          xpc,
          " (",
          round(v[xi], 1),
          "%)"
        ),
        y = paste0(
          ypc,
          " (",
          round(v[yi], 1),
          "%)"
        ),
        colour = colour_label
      )

    if (!is.null(shape_label)) {
      p <- p + labs(shape = shape_label)
    }

    p +
      theme_classic(base_size = 13) +
      theme(
        plot.title = element_text(
          face = "bold",
          hjust = 0.5
        ),
        legend.position = if (
          isTRUE(input$pca_show_legend)
        ) "right" else "none"
      )
  })

  output$pca_plotly <- renderPlotly({
    p <- pca_ggplot()

    ggplotly(
      p,
      tooltip = "text",
      dynamicTicks = TRUE
    ) %>%
      layout(
        dragmode = "zoom",
        hovermode = "closest"
      ) %>%
      config(
        displaylogo = FALSE,
        scrollZoom = TRUE,
        modeBarButtonsToAdd = c(
          "drawline",
          "drawopenpath",
          "drawrect",
          "eraseshape"
        ),
        toImageButtonOptions = list(
          format = "png",
          filename = "PCA_plot",
          scale = 2
        )
      )
  })

  output$scree_plotly <- renderPlotly({
    result <- pca_result()
    v <- result$variance_pct

    n_pc <- min(10, length(v))

    df <- data.frame(
      PC = paste0("PC", seq_len(n_pc)),
      Variance = v[seq_len(n_pc)]
    )

    p <- ggplot(
      df,
      aes(
        x = factor(PC, levels = PC),
        y = Variance,
        text = paste0(
          PC,
          ": ",
          round(Variance, 2),
          "%"
        )
      )
    ) +
      geom_col() +
      labs(
        x = NULL,
        y = "Variance explained (%)"
      ) +
      theme_classic(base_size = 12)

    ggplotly(
      p,
      tooltip = "text"
    ) %>%
      config(
        displaylogo = FALSE,
        toImageButtonOptions = list(
          format = "png",
          filename = "PCA_scree_plot",
          scale = 2
        )
      )
  })

  # ----------------------------------------------------------
  # Summary / tables
  # ----------------------------------------------------------
  output$dataset_summary <- renderPrint({
    e <- eset()
    mat <- exprs(e)
    meta <- sample_metadata()
    info <- mapping_info()

    cat("GEO accession:        ",
        toupper(trimws(input$gse_id)), "\n")
    cat("Platform:             ", annotation(e), "\n")
    cat("Total GEO features:   ", nrow(mat), "\n")
    cat("Total GEO samples:    ", ncol(mat), "\n")
    cat("Selected samples:     ", length(input$selected_samples), "\n")
    cat("Annotation package:   ",
        ifelse(
          is.na(info$package),
          "Not configured",
          info$package
        ),
        "\n\n")

    if ("title" %in% colnames(meta)) {
      cat("Sample titles:\n")

      for (i in seq_len(nrow(meta))) {
        cat(
          paste0(
            "  ",
            meta$Sample_ID[i],
            " -> ",
            meta$title[i],
            "\n"
          )
        )
      }
    }
  })

  output$metadata_table <- renderDT({
    datatable(
      sample_metadata(),
      filter = "top",
      rownames = FALSE,
      options = list(
        scrollX = TRUE,
        pageLength = 10
      )
    )
  })

  output$feature_expression_table <- renderDT({
    mat <- feature_matrix()
    n <- min(input$n_preview, nrow(mat))
    preview_mat <- mat[seq_len(n), , drop = FALSE]

    datatable(
      matrix_to_df(
        preview_mat,
        orientation = input$orientation,
        row_id_name = "Feature_ID"
      ),
      rownames = FALSE,
      options = list(
        scrollX = TRUE,
        scrollY = "500px",
        pageLength = min(20, n)
      )
    )
  })

  output$mapping_summary <- renderPrint({
    info <- mapping_info()

    cat("Platform:            ", info$platform, "\n")
    cat("Annotation package:  ",
        ifelse(
          is.na(info$package),
          "Not configured",
          info$package
        ),
        "\n\n")
    cat(info$message, "\n\n")

    if (isTRUE(info$ok)) {
      cat("Total features:          ", info$total_features, "\n")
      cat("Mapped features:         ", info$mapped_features, "\n")
      cat("Unmapped features:       ", info$unmapped_features, "\n")
      cat("Unique mapped genes:     ", info$unique_genes, "\n")
      cat("Extra duplicate probes:  ",
          info$duplicate_mapped_features, "\n")
    }
  })

  output$mapping_table <- renderDT({
    info <- mapping_info()

    validate(
      need(isTRUE(info$ok), info$message)
    )

    datatable(
      info$mapping,
      filter = "top",
      rownames = FALSE,
      options = list(
        scrollX = TRUE,
        pageLength = 20
      )
    )
  })

  output$gene_expression_table <- renderDT({
    mat <- gene_matrix()
    query <- trimws(input$gene_search)

    if (nzchar(query)) {
      wanted <- unlist(
        strsplit(
          query,
          split = "[,;[:space:]]+"
        )
      )

      wanted <- toupper(wanted[nzchar(wanted)])

      gene_names_upper <- toupper(
        sub(" \\|.*$", "", rownames(mat))
      )

      keep <- gene_names_upper %in% wanted
      mat <- mat[keep, , drop = FALSE]

      validate(
        need(
          nrow(mat) > 0,
          "None of the requested gene symbols were found."
        )
      )
    }

    n <- min(input$n_preview, nrow(mat))
    preview_mat <- mat[seq_len(n), , drop = FALSE]

    datatable(
      matrix_to_df(
        preview_mat,
        orientation = input$orientation,
        row_id_name = "Gene"
      ),
      rownames = FALSE,
      options = list(
        scrollX = TRUE,
        scrollY = "500px",
        pageLength = min(20, n)
      )
    )
  })

  output$combined_table <- renderDT({
    dat <- combined_ml_table()

    metadata_cols <- c(
      "Sample_ID",
      "Group",
      intersect(
        input$metadata_columns,
        colnames(dat)
      )
    )

    gene_cols <- setdiff(
      colnames(dat),
      metadata_cols
    )

    preview_cols <- unique(
      c(
        metadata_cols,
        head(gene_cols, 30)
      )
    )

    datatable(
      dat[, preview_cols, drop = FALSE],
      rownames = FALSE,
      filter = "top",
      options = list(
        scrollX = TRUE,
        pageLength = 15
      )
    )
  })

  output$pca_summary <- renderPrint({
    result <- pca_result()
    v <- result$variance_pct

    cat("Samples used:      ", result$samples_used, "\n")
    cat("Genes used:        ", result$genes_used, "\n")
    cat("Centered:          ", input$pca_center, "\n")
    cat("Scaled:            ", input$pca_scale, "\n\n")

    cat("PC1 variance:      ", round(v[1], 2), "%\n")

    if (length(v) >= 2) {
      cat("PC2 variance:      ", round(v[2], 2), "%\n")
      cat("PC1 + PC2:         ",
          round(v[1] + v[2], 2), "%\n")
    }

    cat("\nImportant:\n")
    cat("PCA uses only gene-expression values.\n")
    cat("Colour/shape variables are added after PCA for interpretation.\n")
    cat("A very distant sample can stretch the plot; use Plotly zoom before\n")
    cat("deciding whether it is a true biological sample or an outlier.\n")
  })

  output$pca_scores_table <- renderDT({
    scores <- pca_scores()

    keep_cols <- c(
      "Sample_ID",
      "Group",
      grep("^PC[0-9]+$", colnames(scores), value = TRUE)
    )

    datatable(
      scores[, keep_cols, drop = FALSE],
      rownames = FALSE,
      options = list(
        scrollX = TRUE,
        pageLength = 15
      )
    )
  })

  # ----------------------------------------------------------
  # Downloads
  # ----------------------------------------------------------
  output$download_combined <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_ML_ready_expression_plus_metadata.csv"
      )
    },
    content = function(file) {
      write.csv(
        combined_ml_table(),
        file,
        row.names = FALSE
      )
    }
  )

  output$download_gene_matrix <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_gene_expression_matrix.csv"
      )
    },
    content = function(file) {
      dat <- matrix_to_df(
        gene_matrix(),
        orientation = input$orientation,
        row_id_name = "Gene"
      )

      write.csv(dat, file, row.names = FALSE)
    }
  )

  output$download_metadata <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_sample_metadata.csv"
      )
    },
    content = function(file) {
      write.csv(
        sample_metadata(),
        file,
        row.names = FALSE
      )
    }
  )

  output$download_pca_scores <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_PCA_coordinates.csv"
      )
    },
    content = function(file) {
      write.csv(
        pca_scores(),
        file,
        row.names = FALSE
      )
    }
  )

  # Static export uses the same current visual settings as the Plotly source ggplot.
  output$download_pca_svg <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_PCA.svg"
      )
    },
    content = function(file) {
      ggplot2::ggsave(
        filename = file,
        plot = pca_ggplot(),
        device = "svg",
        width = 9,
        height = 7,
        units = "in"
      )
    }
  )

  output$download_pca_jpeg <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_PCA.jpg"
      )
    },
    content = function(file) {
      ggplot2::ggsave(
        filename = file,
        plot = pca_ggplot(),
        device = "jpeg",
        width = 9,
        height = 7,
        units = "in",
        dpi = 300
      )
    }
  )

  output$download_pca_png <- downloadHandler(
    filename = function() {
      paste0(
        toupper(trimws(input$gse_id)),
        "_PCA.png"
      )
    },
    content = function(file) {
      ggplot2::ggsave(
        filename = file,
        plot = pca_ggplot(),
        device = "png",
        width = 9,
        height = 7,
        units = "in",
        dpi = 300
      )
    }
  )
}

shinyApp(ui = ui, server = server)
