#' Mark relevant actors
#'
#' @param dataframe A dataframe with identified duplicates.
#' @param prepared_duplicate_data A prepared form of the dataframe after using the function "prepare_duplicate_dataframe".
#' @param min_similarity A numeric specifying the similarity threshold for two strings to be identified as duplicate.
#'
#' @returns Changes the values of the column "relevant" in the initial dataframe to distinguish relevant actors from irrelevant actors and duplicates.
#' @export
#'
#' @examples
#' entity_id <- c(1:4)
#' entity <- c("Philipp Müller", "Miley Cyrus", "Cyrus", "Wagner")
#' document_id <- c(1, 1, 1, 1)
#' relevant <- c(TRUE, TRUE, TRUE, FALSE)
#' duplicate <- c(NA, NA, TRUE, NA)
#' actors_in_document_1 <- data.frame(entity_id, entity, document_id, relevant, duplicate)
#'
#' prepared_dataframe_actors_in_document_1 <- prepare_duplicate_dataframe(actors_in_document_1)
#'
#' relevant_actors_in_document_1 <- mark_relevant_actors(actors_in_document_1, prepared_dataframe_actors_in_document_1, 0.8)
mark_relevant_actors <- function(dataframe, prepared_duplicate_data, min_similarity) {
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
                dplyr::mutate(entity_id_1 = purrr::map_dbl(pairs, ~.x[1]),
                              entity_id_2 = purrr::map_dbl(pairs, ~.x[2])) |> 
                dplyr::filter(!entity_id_1 %in% entity_id_2) |> 
                dplyr::distinct(entity_id_1, .keep_all = TRUE) |> 
                dplyr::mutate(first_mention = TRUE) |> 
                dplyr::select(entity_id_1, first_mention), by = c("entity_id" = "entity_id_1")) |> 
    dplyr::left_join(prepared_duplicate_data |> 
                       dplyr::select(entity_id, last_name), by = "entity_id") |> 
    dplyr::group_by(last_name) |> 
    dplyr::mutate(first_rel = any(relevant == TRUE & !is.na(first_mention))) |> 
    dplyr::ungroup() |> 
    dplyr::mutate(relevant = dplyr::if_else(relevant == TRUE & is.na(first_mention) & !is.na(duplicate) & first_rel == TRUE, FALSE, relevant)) |> 
    dplyr::select(-c(first_mention, last_name, first_rel))
}