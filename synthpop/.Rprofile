is_background_daemon <- !interactive() && (
  identical(Sys.getenv("R_DAEMON"), "TRUE") ||
  !is.null(getOption("callr.condition_handler_env")) ||
  identical(Sys.getenv("CALLR_CHILD_SESSION"), "1")
)

is_rmd_chunk <- !interactive() && !is_background_daemon && (
  any(grep("rmarkdown|knitr", commandArgs(trailingOnly = FALSE))) ||
  any(vapply(c("rmarkdown", "knitr"), isNamespaceLoaded, logical(1)))
)

if (is_background_daemon) {
  # Strict fast exit

} else {

  if (file.exists("renv/activate.R")) source("renv/activate.R")

  options(vscodeR = TRUE)

  vsc_init <- list.files(
    file.path(Sys.getenv("USERPROFILE"), ".vscode/extensions"),
    pattern = "^init\\.R$",
    recursive = TRUE,
    full.names = TRUE
  )
  vsc_init <- vsc_init[grepl("reditorsupport\\.r-", vsc_init)][1]

  if (!is.na(vsc_init) && file.exists(vsc_init)) {
    source(vsc_init, chdir = TRUE, local = FALSE)
    if (exists(".First.sys", envir = globalenv())) {
      .First.sys()
    }

    if (interactive()) {
      message("VS Code Session Watcher: Interactive Environment Connected.")
    } else if (is_rmd_chunk) {
      message("VS Code Session Watcher: Rmd Notebook Chunk Connected.")
      if (requireNamespace("knitr", quietly = TRUE)) {
        knitr::opts_knit$set(envir = .GlobalEnv)
      }
    }
  }

  if (interactive()) {
    options(radian.auto_match = FALSE)
    options(radian.auto_indentation = FALSE)
    options(radian.complete_while_typing = FALSE)
  }
}