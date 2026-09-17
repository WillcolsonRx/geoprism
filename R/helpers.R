# R/helpers.R

annotation_package_for <- function(platform_name) {
  p <- toupper(platform_name)

  if (grepl("GPL570", p) || grepl("HGU133PLUS2", p)) {
    return("hgu133plus2.db")
  }

  if (grepl("GPL6244", p) ||
      grepl("HUGENE10STTRANSCRIPTCLUSTER", p)) {
    return("hugene10sttranscriptcluster.db")
  }

  NULL
}

matrix_to_df <- function(mat,
                         orientation = "feature_rows",
                         row_id_name = "Feature_ID") {
  if (orientation == "sample_rows") {
    out <- as.data.frame(t(mat), check.names = FALSE)
    out <- data.frame(
      Sample_ID = rownames(out),
      out,
      check.names = FALSE
    )
  } else {
    out <- as.data.frame(mat, check.names = FALSE)
    out <- data.frame(
      ID = rownames(out),
      out,
      check.names = FALSE
    )
    colnames(out)[1] <- row_id_name
  }

  rownames(out) <- NULL
  out
}

default_metadata_columns <- function(meta) {
  preferred_patterns <- c(
    "^title$",
    "^source_name_ch1$",
    "^characteristics_ch1",
    "^description$"
  )

  keep <- unique(unlist(
    lapply(
      preferred_patterns,
      function(pat) {
        grep(
          pat,
          colnames(meta),
          ignore.case = TRUE,
          value = TRUE
        )
      }
    )
  ))

  setdiff(keep, "Sample_ID")
}

clean_group_label <- function(x) {
  x <- trimws(as.character(x))
  x[!nzchar(x)] <- "Unassigned"
  x
}

safe_variance <- function(x) {
  v <- apply(x, 1, var, na.rm = TRUE)
  v[!is.finite(v)] <- NA_real_
  v
}
