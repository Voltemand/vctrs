#' Count unique values in a vector
#'
#' Count the number of unique values in a vector. `vec_count()` has two
#' important differences to `table()`: it returns a data frame, and when
#' given multiple inputs (as a data frame), it only counts combinations that
#' appear in the input.
#'
#' @param x A vector (including a data frame).
#' @param sort One of "count", "key", "location", or "none".
#'  * "count", the default, puts most frequent values at top
#'  * "key", orders by the output key column (i.e. unique values of `x`)
#'  * "location", orders by location where key first seen. This is useful
#'     if you want to match the counts up to other unique/duplicated functions.
#'  * "none", leaves unordered.
#' @return A data frame with columns `key` (same type as `x`) and
#'   `count` (an integer vector).
#' @export
#' @examples
#' vec_count(mtcars$vs)
#' vec_count(iris$Species)
#'
#' # If you count a data frame you'll get a data frame
#' # column in the output
#' str(vec_count(mtcars[c("vs", "am")]))
#'
#' # Sorting ---------------------------------------
#'
#' x <- letters[rpois(100, 6)]
#' # default is to sort by frequency
#' vec_count(x)
#'
#' # by can sort by key
#' vec_count(x, sort = "key")
#'
#' # or location of first value
#' vec_count(x, sort = "location")
#' head(x)
#'
#' # or not at all
#' vec_count(x, sort = "none")
vec_count <- function(x, sort = c("count", "key", "location", "none")) {
  sort <- match.arg(sort)

  # Returns key-value pair giving index of first occurence value and count
  kv <- .Call(vctrs_count, vec_proxy_equal(x))

  # rep_along() to support zero-length vectors!
  df <- data.frame(key = rep_along(kv$val, NA), count = kv$val)
  df$key <- vec_slice(x, kv$key) # might be a dataframe

  if (sort == "none")
    return(df)

  idx <- switch(sort,
    location = order(kv$key),
    key = vec_order(df$key),
    count = order(-kv$val)
  )

  df <- df[idx, , drop = FALSE]
  reset_rownames(df)
}

reset_rownames <- function(x) {
  rownames(x) <- NULL

  is_df <- map_lgl(x, is.data.frame)
  x[is_df] <- lapply(x[is_df], `rownames<-`, NULL)

  x
}

# Duplicates --------------------------------------------------------------

#' Find duplicated values
#'
#' * `vec_duplicate_any()`: detects the presence of duplicated values,
#'   similarly to [anyDuplicated()].
#' * `vec_duplicate_detect()`: returns a logical vector describing if each
#'   element of the vector is duplicated elsewhere. Unlike [duplicated()], it
#'   reports all duplicated values, not just the second and subsequent
#'   repetitions.
#' * `vec_duplicate_id()`: returns an integer vector given the location of
#'   the first occurence of the value
#'
#' @section Missing values:
#' In most cases, missing values are not considered to be equal, i.e.
#' `NA == NA` is not `TRUE`. This behaviour would be unappealing here,
#' so these functions consider all `NAs` to be equal. (Similarly,
#' all `NaN` are also considered to be equal.)
#'
#' @section Performance:
#' These functions are currently slightly slower than their base equivalents.
#' This is primarily because they do a little more checking and coercion
#' in R, which makes them both a litter safer and more generic. Additionally,
#' the C code underlying vctrs has not yet been implemented: we expect
#' some performance improvements when that happens.
#'
#' @param x A vector (including a data frame).
#' @return
#'   * `vec_duplicate_any()`: a logical vector of length 1.
#'   * `vec_duplicate_detect()`: a logical vector the same length as `x`
#'   * `vec_duplicate_id()`: an integer vector the same length as `x`
#' @seealso [vec_unique()] for functions that work with the dual of duplicated
#'   values: unique values.
#' @name vec_duplicate
#' @examples
#' vec_duplicate_any(1:10)
#' vec_duplicate_any(c(1, 1:10))
#'
#' x <- c(10, 10, 20, 30, 30, 40)
#' vec_duplicate_detect(x)
#' # Note that `duplicated()` doesn't consider the first instance to
#' # be a duplicate
#' duplicated(x)
#'
#' # Identify elements of a vector by the location of the first element that
#' # they're equal to:
#' vec_duplicate_id(x)
#' # Location of the unique values:
#' vec_unique_loc(x)
#' # Equivalent to `duplicated()`:
#' vec_duplicate_id(x) == seq_along(x)
NULL

#' @rdname vec_duplicate
#' @export
vec_duplicate_any <- function(x) {
  x <- vec_proxy_equal(x)
  .Call(vctrs_duplicated_any, x)
}

#' @rdname vec_duplicate
#' @export
vec_duplicate_detect <- function(x) {
  x <- vec_proxy_equal(x)
  .Call(vctrs_duplicated, x)
}

#' @rdname vec_duplicate
#' @export
vec_duplicate_id <- function(x) {
  x <- vec_proxy_equal(x)
  .Call(vctrs_id, x)
}

# Unique values -----------------------------------------------------------

#' Find and count unique values
#'
#' * `vec_unique()`: the unique values. Equivalent to [unique()].
#' * `vec_unique_loc()`: the locations of the unique values.
#' * `vec_unique_count()`: the number of unique values.
#'
#' @inherit vec_duplicate sections
#' @param x A vector (including a data frame).
#' @return
#' * `vec_unique()`: a vector the same type as `x` containining only unique
#'    values.
#' * `vec_unique_loc()`: an integer vector, giving locations of unique values.
#' * `vec_unique_count()`: an integer vector of length 1, giving the
#'   number of unique values.
#' @seealso [vec_duplicate] for functions that work with the dual of
#'   unique values: duplicated values.
#' @export
#' @examples
#' x <- rpois(100, 8)
#' vec_unique(x)
#' vec_unique_loc(x)
#' vec_unique_count(x)
#'
#' # `vec_unique()` returns values in the order that encounters them
#' # use sort = "location" to match to the result of `vec_count()`
#' head(vec_unique(x))
#' head(vec_count(x, sort = "location"))
#'
#' # Normally missing values are not considered to be equal
#' NA == NA
#'
#' # But they are for the purposes of considering uniqueness
#' vec_unique(c(NA, NA, NA, NA, 1, 2, 1))
vec_unique <- function(x) {
  px <- vec_proxy_equal(x)
  vec_slice(x, vec_unique_loc(px))
}

#' @rdname vec_unique
#' @export
vec_unique_loc <- function(x) {
  x <- vec_proxy_equal(x)
  .Call(vctrs_unique_loc, x)
}

#' @rdname vec_unique
#' @export
vec_unique_count <- function(x) {
  x <- vec_proxy_equal(x)
  .Call(vctrs_n_distinct, x)
}


# Matching ----------------------------------------------------------------

#' Find matching observations across vectors
#'
#' `vec_in()` returns a logical vector based on whether `needle` is found in
#' haystack. `vec_match()` returns an integer vector giving location of
#' `needle` in `haystack`, or `NA` if it's not found.
#'
#' `vec_in()` is equivalent to [%in%]; `vec_match()` is equivalen to `match()`.
#'
#' @inherit vec_duplicate sections
#' @param needles,haystack Vector of `needles` to search for in vector haystack.
#'   `haystack` should usually be unique; if not `vec_match()` will only
#'   return the location of the first match.
#'
#'   `needles` and `haystack` are coerced to the same type prior to
#'   comparison.
#' @return A vector the same length as `needles`. `vec_in()` returns a
#'   logical vector; `vec_match()` returns an integer vector.
#' @export
#' @examples
#' hadley <- strsplit("hadley", "")[[1]]
#' vec_match(hadley, letters)
#'
#' vowels <- c("a", "e", "i", "o", "u")
#' vec_match(hadley, vowels)
#' vec_in(hadley, vowels)
#'
#' # Only the first index of duplicates is returned
#' vec_match(c("a", "b"), c("a", "b", "a", "b"))
vec_match <- function(needles, haystack) {
  v <- vec_cast_common(needles = needles, haystack = haystack)
  .Call(vctrs_match, vec_proxy_equal(v$needles), vec_proxy_equal(v$haystack))
}

#' @export
#' @rdname vec_match
vec_in <- function(needles, haystack) {
  v <- vec_cast_common(needles = needles, haystack = haystack)
  .Call(vctrs_in, vec_proxy_equal(v$needles), vec_proxy_equal(v$haystack))
}


# Splitting ---------------------------------------------------------------

#' Split a vector into groups
#'
#' This is a generalisation of [split()] that can split by any type of vector,
#' not just factors. Instead of returning the keys in the character names,
#' the are returned in a separate parallel vector.
#'
#' @param x Vector to divide into groups.
#' @param by Vector whose unique values defines the groups.
#' @return A data frame with two columns and size equal to
#'   `vec_size(vec_unique(by))`. The `key` column has the same type as
#'   `by`, and the `val` column has type `list_of<vec_type(x)>`.
#'
#'   Note for complex types, the default `data.frame` print method will be
#'   suboptimal, and you will want to coerce into a tibble to better
#'   understand the output.
#' @export
#' @examples
#' vec_split(mtcars$cyl, mtcars$vs)
#' vec_split(mtcars$cyl, mtcars[c("vs", "am")])
#'
#' if (require("tibble")) {
#'   as_tibble(vec_split(mtcars$cyl, mtcars[c("vs", "am")]))
#'   as_tibble(vec_split(mtcars, mtcars[c("vs", "am")]))
#' }
vec_split <- function(x, by) {
  if (vec_size(x) != vec_size(by)) {
    abort("`x` and `by` must have same size")
  }

  ki <- vec_duplicate_split(by)
  keys <- vec_slice(by, ki$key)
  x_split <- map(ki$idx, vec_slice, x = x)

  vals <- new_list_of(x_split, vec_type(x))

  new_data_frame(list(key = keys, val = vals), n = vec_size(keys))
}

# Returns key-index pair giving the index of first key occurence and
# a list containing the locations of each key
vec_duplicate_split <- function(x) {
  x <- vec_proxy_equal(x)
  .Call(vctrs_duplicate_split, x)
}
