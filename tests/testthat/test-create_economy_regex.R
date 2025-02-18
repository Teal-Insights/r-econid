library(testthat)

test_that("Non-character input throws an error", {
  expect_error(
    create_economy_regex(123),
    "`names` must be a character vector."
  )
})

test_that("Empty character vector returns an empty string", {
  expect_identical(create_economy_regex(character(0)), "")
})

test_that("Single input is lowercased", {
  result <- create_economy_regex("ABC")
  expect_equal(result, "abc")
})

test_that("Special regex characters are escaped", {
  # For "A.B" the period should be escaped, producing "a\\.b"
  result <- create_economy_regex("A.B")
  expect_equal(result, "a\\.b")
})

test_that("Multiple names are joined with a pipe", {
  # "New York" -> tolower: "new york" then space replaced by ".?" -> "new.?york"
  result <- create_economy_regex(c("New York", "LA", "A.B"))
  expect_equal(result, "new.?york|la|a\\.b")
})

test_that("Multiple whitespaces are replaced by a single .?", {
  # "San   Francisco" should have all consecutive spaces replaced with ".?"
  result <- create_economy_regex("San   Francisco")
  expect_equal(result, "san.?francisco")
})

test_that("Names w/ several regex special characters are processed correctly", {
  # For example: "Hello.World (test)"
  # Steps:
  # tolower: "hello.world (test)"
  # Escape special characters:
  #   period becomes "\\."
  #   parentheses becomes "\\(" and "\\)"
  # Replace space -> ".?"
  # Final pattern -> "hello\\.world.?\\(test\\)"
  result <- create_economy_regex("Hello.World (test)")
  expect_equal(result, "hello\\.world.?\\(test\\)")
})
