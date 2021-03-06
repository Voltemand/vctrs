context("test-list_of")

test_that("list_of works like list", {
  x1 <- list_of(1, 1)
  expect_type(x1, "list")
  expect_s3_class(x1, "vctrs_list_of")
  expect_equal(attr(x1, "ptype"), double())

  x2 <- list_of(1, 1, .ptype = integer())
  expect_equal(attr(x1, "ptype"), integer())

  x3 <- as_list_of(list(1, 1))
  expect_equal(x3, x1)

  x4 <- list_of(a = 1, b = 2)
  expect_equal(x4$b, 2)
  expect_error(x4$c, "Invalid index", fixed = TRUE)
})

test_that("list_of errors if it can't find common type", {
  expect_error(list_of(1, "a"), class = "vctrs_error_incompatible_type")
  expect_error(list_of(), "find common type")
})

test_that("can use as_list_of to change type", {
  x1 <- list_of(1)
  expect_equal(as_list_of(x1), x1)

  x2 <- as_list_of(x1, .ptype = integer())
  expect_identical(x2[[1]], 1L)
})

test_that("is_list_of as expected", {
  expect_false(is_list_of(list(1)))
  expect_true(is_list_of(list_of(1)))
})

test_that("print method gives human friendly output", {
  x <- list_of(1, 2:3)

  expect_known_output({
      print(x)
      cat("\n")
      print(tibble::tibble(x))
    },
    file = test_path("test-list_of-print.txt")
  )
})

test_that("str method is reasonably correct", {
  x <- list_of(1, 2:3)

  expect_known_output({
      str(x)
      cat("\n")
      str(list(list(x, y = 2:1)))
    },
    file = test_path("test-list_of-str.txt")
  )

  expect_known_output({
      str(x[0])
      cat("\n")
      str(list(list(x, y = 2:1)))
    },
    file = test_path("test-list_of-str-empty.txt")
  )
})

# Subsetting --------------------------------------------------------------

test_that("[ preserves type", {
  x <- list_of(1)
  expect_equal(x[1], x)
})

test_that("[<-, [[<- and $<- coerce their input", {
  # Seems to be some bug in R 3.1 where NextMethod() called from $.list_of
  # causes an error "invalid subscript type 'promise'"
  skip_if_not(getRversion() >= "3.2")

  x <- list_of(x = 1, y = 1, z = 1, w = 1)
  x[1] <- list(FALSE)
  x
  x[[2]] <- FALSE
  x
  x$z <- FALSE
  x

  expect_equal(x, list_of(x = 0, y = 0, z = 0, w = 1))

  x[[2]] <- NULL
  expect_equal(x, list_of(x = 0, y = NULL, z = 0, w = 1))

  x[3:4] <- list(NULL)
  expect_equal(x, list_of(x = 0, y = NULL, z = NULL, w = NULL))

  expect_equal(is.na(x), c(FALSE, TRUE, TRUE, TRUE))
})

test_that("assingment can increase size of vector", {
  # Seems to be some bug in R 3.1 where NextMethod() called from $.list_of
  # causes an error "invalid subscript type 'promise'"
  skip_if_not(getRversion() >= "3.2")

  x <- list_of(x = 1)
  x[[2]] <- 2
  x$z <- 3
  x[4:5] <- c(4,5)

  expect_length(x, 5)
})


# Type system -------------------------------------------------------------

test_that("list_of() are vectors", {
  expect_true(vec_is_vector(list_of(1)))
  expect_true(vec_is(list_of(1)))
})

test_that("list coercions are symmetric and unchanging", {
  types <- list(
    list(),
    list_of(.ptype = integer()),
    list_of(.ptype = double()),
    list_of(.ptype = character())
  )
  mat <- maxtype_mat(types)

  expect_true(isSymmetric(mat))
  expect_known_output(
    mat,
    test_path("test-list_of-type.txt"),
    print = TRUE,
    width = 200
  )
})

test_that("max<list_of<a>, list_of<b>> is list_of<max<a, b>>", {
  r_int <- list_of(.ptype = integer())
  r_dbl <- list_of(.ptype = double())

  expect_equal(vec_type_common(r_int, r_int), r_int)
  expect_equal(vec_type_common(r_int, r_dbl), r_int)
})

test_that("safe casts work as expected", {
  x <- list_of(1)
  expect_equal(vec_cast(NULL, x), NULL)
  expect_equal(vec_cast(1L, x), x)
  expect_equal(vec_cast(1, x), x)
  expect_equal(vec_cast(list(1), x), x)
  expect_equal(vec_cast(list(TRUE), x), x)
  expect_equal(vec_cast(NA, x), list_of(NULL, .ptype = double()))
  expect_identical(vec_cast(x, list()), list(1))
})

test_that("lossy casts generate warning", {
  expect_lossy(
    vec_cast(list(c(1.5, 1), 1L), to = list_of(1L)),
    list_of(int(1L, 1L), 1L),
    x = dbl(), to = int()
  )
})

test_that("invalid casts generate error", {
  expect_error(vec_cast(factor("a"), list_of(1)), class = "vctrs_error_incompatible_cast")
})

test_that("validation", {
  expect_error(validate_list_of(list_of(1, 2, 3)), NA)
  expect_error(
    validate_list_of(new_list_of(list(1, "a", 3), dbl())),
    class = "vctrs_error_cast_lossy"
  )
})
