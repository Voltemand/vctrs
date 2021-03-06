# Print -------------------------------------------------------------------

#' 64 bit integers
#'
#' A `integer64` is a 64 bits integer vector, implemented in the `bit64` package.
#'
#' These functions help the `integer64` class from `bit64` in to
#' the vctrs type system by providing coercion functions
#' and casting functions.
#'
#' @keywords internal
#' @rdname int64
#' @export
vec_ptype_full.integer64 <- function(x) {
  "integer64"
}

#' @rdname int64
#' @export
vec_ptype_abbr.integer64 <- function(x) {
  "int64"
}


# Coerce ------------------------------------------------------------------

#' @export
#' @rdname int64
#' @export vec_type2.integer64
#' @method vec_type2 integer64
vec_type2.integer64 <- function(x, y) {
  UseMethod("vec_type2.integer64", y)
}

#' @method vec_type2.integer64 default
#' @export
vec_type2.integer64.default <- function(x, y) stop_incompatible_type(x, y)


#' @method vec_type2.integer64 vctrs_unspecified
#' @export
vec_type2.integer64.vctrs_unspecified <- function(x, y) bit64::integer64()

#' @method vec_type2.vctrs_unspecified integer64
#' @export
vec_type2.vctrs_unspecified.integer64 <- function(x, y) bit64::integer64()


#' @method vec_type2.integer64 integer64
#' @export
vec_type2.integer64.integer64 <- function(x, y) bit64::integer64()


#' @method vec_type2.integer64 integer
#' @export
vec_type2.integer64.integer <- function(x, y) bit64::integer64()

#' @method vec_type2.integer integer64
#' @export
vec_type2.integer.integer64 <- function(x, y) bit64::integer64()


#' @method vec_type2.integer64 logical
#' @export
vec_type2.integer64.logical <- function(x, y) bit64::integer64()

#' @method vec_type2.logical integer64
#' @export
vec_type2.logical.integer64 <- function(x, y) bit64::integer64()


# Cast --------------------------------------------------------------------

#' @export
#' @rdname int64
#' @export vec_cast.integer64
#' @method vec_cast integer64
vec_cast.integer64 <- function(x, to) UseMethod("vec_cast.integer64")

#' @export
#' @method vec_cast.integer64 default
vec_cast.integer64.default <- function(x, to) stop_incompatible_cast(x, to)

#' @export
#' @method vec_cast.integer64 integer64
vec_cast.integer64.integer64 <- function(x, to) x

#' @export
#' @method vec_cast.integer64 vctrs_unspecified
vec_cast.integer64.vctrs_unspecified <- function(x, to) vec_unspecified_cast(x, to)

#' @export
#' @method vec_cast.integer64 integer
vec_cast.integer64.integer <- function(x, to) {
  bit64::as.integer64(x)
}

#' @export
#' @method vec_cast.integer integer64
vec_cast.integer.integer64 <- function(x, to) {
  as.integer(x)
}

#' @export
#' @method vec_cast.integer64 logical
vec_cast.integer64.logical <- function(x, to) {
  bit64::as.integer64(x)
}

#' @export
#' @method vec_cast.logical integer64
vec_cast.logical.integer64 <- function(x, to) {
  as.logical(x)
}

#' @export
#' @method vec_cast.integer64 character
vec_cast.integer64.character <- function(x, to) {
  bit64::as.integer64(x)
}

#' @export
#' @method vec_cast.character integer64
vec_cast.character.integer64 <- function(x, to) {
  as.character(x)
}

#' @export
#' @method vec_cast.integer64 double
vec_cast.integer64.double <- function(x, to) {
  bit64::as.integer64(x)
}

#' @export
#' @method vec_cast.double integer64
vec_cast.double.integer64 <- function(x, to) {
  as.double(x)
}
