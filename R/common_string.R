#' common_string
#'
#' @param entity_1 A string containing the first word to be compared.
#' @param entity_2 A string containing the second word to be compared.
#'
#' @returns The number of common letters at similar positions.
#' @export
#'
#' @examples
#' common_string("Paul", "Paul Panther")
#'
#' common_string("Maria", "Paul")
common_string <- function(entity_1, entity_2) {
  m <- nchar(entity_1); n <- nchar(entity_2)
  dp <- matrix(0, nrow = m + 1, ncol = n + 1)
  maxlen <- 0
  for (i in seq_len(m)) {
    for (j in seq_len(n)) {
      if (substr(entity_1, i, i) == substr(entity_2, j, j)) {
        dp[i + 1, j + 1] <- dp[i, j] + 1
        maxlen <- max(maxlen, dp[i + 1, j + 1])
      }
    }
  }
  maxlen
}
