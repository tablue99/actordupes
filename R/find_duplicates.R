#' find_duplicates
#'
#' @param dataframe The raw dataframe where duplicates should be identified.
#' @param prepared_duplicate_data A prepared form of the dataframe after using the function "prepare_duplicate_dataframe".
#' @param min_similarity A numeric specifying the similarity threshold for two strings to be identified as duplicate.
#'
#' @returns Adds a column "duplicate" to the initial dataframe that contains "TRUE" for all duplicates.
#' @export
#'
#' @examples
#' entity_id <- c(1:4)
#' entity <- c("Philipp Müller", "Miley Cyrus", "Cyrus", "Wagner")
#' document_id <- c(1, 1, 1, 1)
#' actors_in_document_1 <- data.frame(entity_id, entity, document_id)
#'
#' prepared_dataframe_actors_in_document_1 <- prepare_duplicate_dataframe(actors_in_document_1)
#'
#' actors_in_document_1_with_duplicates <- find_duplicates(actors_in_document_1, prepared_dataframe_actors_in_document_1, 0.8)
find_duplicates <- function(dataframe, prepared_duplicate_data, min_similarity) {
  data <- dataframe |>
    dplyr::left_join(prepared_duplicate_data |>
                dplyr::select(document_id, entity_id, last_name) |>
                dplyr::group_by(document_id) |>
                dplyr::summarise(pairs = list(combn(entity_id, 2, simplify = FALSE)),
                          .groups = "drop") |>
                tidyr::unnest(pairs) |>
                dplyr::rowwise() |>
                dplyr::mutate(entity_1 = prepared_duplicate_data$last_name[which(prepared_duplicate_data$entity_id == pairs[[1]])],
                       entity_2 = prepared_duplicate_data$last_name[which(prepared_duplicate_data$entity_id == pairs[[2]])]) |>
                dplyr::mutate(common_strings = common_string(entity_1, entity_2),
                       shorter_name = min(nchar(entity_1), nchar(entity_2))) |>
                dplyr::mutate(similarity = dplyr::if_else(shorter_name > 1, common_strings / shorter_name, 0)) |>
                dplyr::ungroup() |>
                dplyr::filter(similarity >= min_similarity) |>
                dplyr::mutate(entity_id_1 = purrr::map_dbl(pairs, ~ .x[1]),
                       entity_id_2 = purrr::map_dbl(pairs, ~ .x[2])) |>
                dplyr::distinct(entity_id_2, .keep_all = TRUE) |>
                dplyr::mutate(duplicate = TRUE) |>
                dplyr::select(entity_id_2, duplicate), by = c("entity_id" = "entity_id_2"))
}
