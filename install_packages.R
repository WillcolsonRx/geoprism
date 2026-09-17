# install_packages.R
# Run once in this RStudio project.

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

install.packages(c(
  "shiny",
  "DT",
  "ggplot2",
  "plotly",
  "svglite"
))

BiocManager::install(c(
  "GEOquery",
  "AnnotationDbi",
  "hgu133plus2.db",
  "hugene10sttranscriptcluster.db"
))
