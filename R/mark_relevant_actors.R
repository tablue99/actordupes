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