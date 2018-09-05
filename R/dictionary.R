vec_duplicated <- function(x) {
  .Call(vctrs_duplicated, x)
}

vec_duplicated_any <- function(x) {
  .Call(vctrs_duplicated_any, x)
}

vec_unique <- function(x) {
  # TODO: explore C function that returns indices
  vec_subset(x, which(!vec_duplicated(x)))
}

vec_n_distinct <- function(x) {
  .Call(vctrs_n_distinct, x)
}

vec_count <- function(x, order = TRUE) {
  kv <- .Call(vctrs_count, x)

  df <- data.frame(key = 0, count = kv$val)
  df$key <- vec_subset(x, kv$key) # might be a dataframe

  if (order) {
    df <- df[order(kv$key), , drop = FALSE]
    rownames(df) <- NULL
  }

  df
}

vec_id <- function(x) {
  .Call(vctrs_id, x)
}

vec_match <- function(needles, haystack) {
  v <- vec_coerce(needles = needles, haystack = haystack)
  .Call(vctrs_match, v$needles, v$haystack)
}
