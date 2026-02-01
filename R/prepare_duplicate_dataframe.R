#' prepare_duplicate_dataframe
#'
#' @param dataframe A dataframe to be transformed.
#'
#' @returns A dataframe with 6 columns.
#' @export
#'
#' @examples
#' entity_id <- c(1:4)
#' entity <- c("Philipp Müller", "Miley Cyrus", "Cyrus", "Wagner")
#' document_id <- c(1, 1, 1, 1)
#' actors_in_document_1 <- data.frame(entity_id, entity, document_id)
#'
#' prepared_dataframe_actors_in_document_1 <- prepare_duplicate_dataframe(actors_in_document_1)
prepare_duplicate_dataframe <- function(dataframe) {
  data <- dataframe |>
    dplyr::select(entity_id, entity, document_id) |>
    dplyr::mutate(entity_low = stringr::str_to_lower(entity)) |>
    dplyr::mutate(first_name = stringr::str_extract(entity_low, "^[^\\s]+"),
           last_name = stringr::str_extract(entity_low, "[^\\s]+$")) |>
    dplyr::anti_join(dataframe |>
                dplyr::group_by(document_id) |>
                dplyr::summarise(actors = dplyr::n()) |>
                dplyr::filter(actors == 1), by = "document_id")
}
