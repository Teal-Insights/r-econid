test_that("create_economy_regex generates correct patterns", {
  expect_equal(
    create_economy_regex("United States"),
    "united.?states"
  )

  expect_equal(
    create_economy_regex("Test.Pattern(*)"),
    "test\\.pattern\\(\\*\\)"
  )
})
