# Constructor and basic methods  ---------------------------------------------

#' rcrd (record) S3 class
#'
#' The rcrd class extends [vctr]. A rcrd is composed of 1 or more [field]s,
#' which must be vectors of the same length. Is designed specifically for
#' classes that can naturally be decomposed into multiple vectors of the same
#' length, like [POSIXlt], but where the organisation should be considered
#' an implementation detail invisible to the user (unlike a [data.frame]).
#'
#' @param fields A list. It must possess the following properties:
#'   * no attributes (apart from names)
#'   * syntactic names
#'   * length 1 or greater
#'   * elements are vectors
#'   * elements have equal length
#' @param ... Additional attributes
#' @param class Name of subclass.
#' @export
#' @aliases ses rcrd
#' @keywords internal
new_rcrd <- function(fields, ..., class = character()) {
  check_fields(fields)
  structure(fields, ..., class = c(class, "vctrs_rcrd", "vctrs_vctr"))
}

check_fields <- function(fields) {
  if (!is.list(fields) || length(fields) == 0) {
    abort("`fields` must be a list of length 1 or greater.")
  }

  if (!has_unique_names(fields)) {
    abort("`fields` must have unique names.")
  }

  if (!identical(names(attributes(fields)), "names")) {
    abort("`fields` must have no attributes (apart from names).")
  }

  is_vector <- map_lgl(fields, is_vector)
  if (!all(is_vector)) {
    abort("Every field must be a vector.")
  }

  lengths <- map_int(fields, length)
  if (!all_equal(lengths)) {
    abort("Every field must be the same length.")
  }

  invisible(fields)
}

#' @export
vec_proxy.vctrs_rcrd <- function(x) {
  new_data_frame(unclass(x))
}

#' @export
length.vctrs_rcrd <- function(x) {
  .Call(vctrs_size, x)
}

#' @export
names.vctrs_rcrd <- function(x) {
  NULL
}

#' @export
format.vctrs_rcrd <- function(x, ...) {
  # nocov start
  stop_unimplemented(x, "format")
  # nocov end
}

#' @export
obj_str_data.vctrs_rcrd <- function(x, ...) {
  obj_str_leaf(x, ...)
}

#' @method vec_cast vctrs_rcrd
#' @export
vec_cast.vctrs_rcrd <- function(x, to) UseMethod("vec_cast.vctrs_rcrd")

#' @method vec_cast.vctrs_rcrd vctrs_rcrd
#' @export
vec_cast.vctrs_rcrd.vctrs_rcrd <- function(x, to) {
  # This assumes that we don't have duplicate field names,
  # which is verified even in the constructor.
  if (!setequal(fields(x), fields(to))) {
    stop_incompatible_cast(x, to)
  }

  new_data <- map2(
    vec_data(x)[fields(to)],
    vec_data(to),
    vec_cast
  )

  new_rcrd(new_data)
}

#' @method vec_cast.vctrs_rcrd default
#' @export
vec_cast.vctrs_rcrd.default <- function(x, to) {
  if (is_bare_list(x)) {
    vec_list_cast(x, to)
  } else {
    stop_incompatible_cast(x, to)
  }
}

# Subsetting --------------------------------------------------------------

#' @export
`[.vctrs_rcrd` <-  function(x, i, ...) {
  check_dots_empty_s3_consistency(...)
  vec_slice_native(x, i)
}

#' @export
`[[.vctrs_rcrd` <- function(x, i, ...) {
  out <- lapply(vec_data(x), `[[`, i, ...)
  vec_restore(out, x)
}

#' @export
`$.vctrs_rcrd` <- function(x, i, ...) {
  stop_unsupported(x, "subsetting with $")
}

#' @export
rep.vctrs_rcrd <- function(x, ...) {
  out <- lapply(vec_data(x), rep, ...)
  vec_restore(out, x)
}

#' @export
`length<-.vctrs_rcrd` <- function(x, value) {
  out <- lapply(vec_data(x), `length<-`, value)
  vec_restore(out, x)
}

#' @export
as.list.vctrs_rcrd <- function(x, ...) {
  vec_cast(x, list())
}

# Replacement -------------------------------------------------------------

#' @export
`[[<-.vctrs_rcrd` <- function(x, i, value) {
  value <- vec_cast(value, x)
  out <- map2(vec_data(x), vec_data(value), function(x, value) {
    x[[i]] <- value
    x
  })
  vec_restore(out, x)
}

#' @export
`$<-.vctrs_rcrd` <- function(x, i, value) {
  stop_unsupported(x, "subset assignment with $")
}

#' @export
`[<-.vctrs_rcrd` <- function(x, i, value) {
  value <- vec_cast(value, x)

  if (missing(i)) {
    replace <- function(x, value) {
      x[] <- value
      x
    }
  } else {
    replace <- function(x, value) {
      x[i] <- value
      x
    }
  }
  out <- map2(vec_data(x), vec_data(value), replace)
  vec_restore(out, x)
}

# Equality and ordering ---------------------------------------------------

#' @export
vec_proxy_equal.vctrs_rcrd <- function(x)  {
  new_data_frame(vec_data(x), n = length(x))
}

#' @export
vec_proxy_compare.vctrs_rcrd <- function(x, relax = FALSE) {
  new_data_frame(vec_data(x), n = length(x))
}

#' @export
vec_math.vctrs_rcrd <- function(fun, x, ...) {
  stop_unsupported(x, "vec_math")
}

# Test class ---------------------------------------------------------------

# This simple class is used for testing as defining methods inside
# a test does not work (because the lexical scope is lost)
# nocov start

tuple <- function(x = integer(), y = integer()) {
  fields <- vec_recycle_common(
    x = vec_cast(x, integer()),
    y = vec_cast(y, integer())
  )
  new_rcrd(fields, class = "tuple")
}

format.tuple <- function(x, ...) {
  paste0("(", field(x, "x"), ",", field(x, "y"), ")")
}

vec_type2.tuple <- function(x, y)  UseMethod("vec_type2.tuple", y)
vec_type2.tuple.vctrs_unspecified <- function(x, y) tuple()
vec_type2.tuple.tuple <- function(x, y) tuple()
vec_type2.tuple.default <- function(x, y) stop_incompatible_type(x, y)

vec_cast.tuple <- function(x, to) UseMethod("vec_cast.tuple")
vec_cast.tuple.list <- function(x, to) vec_list_cast(x, to)
vec_cast.tuple.tuple <- function(x, to) x

# nocov end
