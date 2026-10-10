# Mechanical conversion of UTF-8 source string literals for R portability.
# R documentation comments stay human-readable; runtime text is unchanged.
files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (path in files) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  code <- !grepl("^\\s*#", lines)
  lines[code] <- vapply(lines[code], function(line) {
    chars <- utf8ToInt(line)
    paste(vapply(chars, function(char) {
      if (char <= 127) intToUtf8(char)
      else if (char <= 65535) sprintf("\\u%04x", char)
      else sprintf("\\U%08x", char)
    }, character(1)), collapse = "")
  }, character(1))
  writeLines(lines, path, useBytes = TRUE)
}
