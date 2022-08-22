test_that("make_filename return the expected format", {
  expect_equal(make_filename(2013),
               "accident_2013.csv.bz2")
})
