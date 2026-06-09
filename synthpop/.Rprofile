# 1. EARLY EXIT: If this is a background diagnostic process (like callr or languageserver),
# exit immediately so it doesn't hang, time out, and crash the workspace sync.
if (!interactive() || 
    identical(Sys.getenv("R_DAEMON"), "TRUE") || 
    any(grep("languageserver", commandArgs(trailingOnly = FALSE)))) {
  
  # Allow standard renv activation for background tasks without running profile loops
  if (file.exists("renv/activate.R")) source("renv/activate.R")
  
} else {
  
  # 2. PROPER INTERACTIVE SESSION (Your Radian Terminal / Notebook Execution)
  source("renv/activate.R")
  
  options(vscodeR = TRUE)
  
  # Absolute path to your extension's init file
  vsc_init <- file.path(
    Sys.getenv("USERPROFILE"), 
    ".vscode/extensions/reditorsupport.r-2.8.8/R/session/init.R"
  )
  
  if (file.exists(vsc_init)) {
    source(vsc_init, chdir = TRUE, local = TRUE)
    
    # Force immediate manual attachment check for R 4.6.0
    if ("tools:vscode" %in% search()) {
      .vsc.attach <- get(".vsc.attach", pos = "tools:vscode")
      .vsc.attach()
    }
    message("VS Code Session Watcher: Interactive Environment Connected.")
  }

  # 3. Your Radian Terminal Console Preferences
  options(radian.auto_match = FALSE)
  options(radian.auto_indentation = FALSE)
  options(radian.complete_while_typing = FALSE)
}