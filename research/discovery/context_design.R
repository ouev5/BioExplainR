# Parse only published design metadata; do not infer donors from expression.
parse_context_design <- function(raw, values) {
    get <- function(key) values[[which(vapply(values, function(v) v[[1]] == key, logical(1)))]] [-1]
    title <- get("!Sample_title"); sample <- get("!Sample_geo_accession")
    chars <- values[vapply(values, function(v) v[[1]] == "!Sample_characteristics_ch1", logical(1))]
    field <- function(prefix) {
        rows <- chars[vapply(chars, function(v) all(startsWith(v[-1], prefix)), logical(1))]
        stopifnot(length(rows) == 1L); substring(rows[[1]][-1], nchar(prefix)+1L)
    }
    donor <- field("donor: "); treatment <- field("treatment: ")
    stopifnot(all(title == paste(donor, treatment, sep = "-")),
              all(treatment %in% outer(c("siCTRL", "siCEBPD"), c("control", "Bud", "TNF", "TNFposBud"), paste, sep = "-")))
    count_column <- paste0("count_", title)
    stopifnot(setequal(count_column, names(raw)[-1]))
    exposure <- sub("^[^-]+-", "", treatment)
    md <- data.frame(sample, title, count_column, donor, treatment,
        kd = ifelse(startsWith(treatment, "siCTRL-"), "NT", "KD"),
        bud = ifelse(exposure %in% c("Bud", "TNFposBud"), "yes", "no"),
        tnf = ifelse(exposure %in% c("TNF", "TNFposBud"), "yes", "no"))
    stopifnot(!anyDuplicated(md[c("donor", "kd", "bud", "tnf")]))
    grid <- expand.grid(donor = unique(donor), kd = c("NT", "KD"), bud = c("no", "yes"), tnf = c("no", "yes"))
    key <- function(x) do.call(paste, c(x[c("donor", "kd", "bud", "tnf")], sep = ":"))
    missing <- grid[!key(grid) %in% key(md), ]
    stopifnot(nrow(missing) == 1L, missing$donor == "N010912", missing$kd == "KD",
              missing$bud == "yes", missing$tnf == "no")
    md
}
