
<!-- README.md is generated from README.Rmd. Please edit that file -->

# actordupes

<!-- badges: start -->

<!-- badges: end -->

The goal of actordupes is to provide a set of synchronised functions to
filter duplicates from datasets that already contain actors who are
already categorised with regards to the questions whether they are the
author of an article (journalist), non-human entities
(misclassification) or passive (no direct/indirect quote). It was
developed to preprocess actor datasets that had been coded by a local
Large Language Model for further manual coding without manually exclude
duplicates in that stage of data collection. **Important note**: As it
is common for journalistic texts to provide full names (sur- and last
name) and only last names for most actors, as well as exclusively
surnames for actors who, for example, wish to remain anonymous, the
detection of duplicates is mainly based on last names and/or the last
given name. So if there is just a surname available it will compare the
surname of the person with last names or people whose full name is
included. In some cases, this can lead to wrong classifications of
duplicates. The functions in the package are not designed to be applied
to datasets containing mostly/exclusively surnames.

## Installation

You can install the development version of actordupes from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("tablue99/actordupes")
```

## Example

The basic structure of datasets set out to be cleaned with the functions
in this package needs to contain at least four variables. Firstly, a
distinct ID for each actor (entity_id), their name (entity), an ID of
the article in which they were identified (document_id) and a variable
containing the preliminary decision (of the LLM) on whether the actor is
relevant (relevant).

    #>   entity_id         entity document_id relevant
    #> 1         1 Philipp Müller           1     TRUE
    #> 2         2    Miley Cyrus           1     TRUE
    #> 3         3          Cyrus           1     TRUE
    #> 4         4         Wagner           1    FALSE
    #> 5         5 Richard Wagner           1     TRUE

To receive a clean version of the actor dataset with a correct
indication of active, thus relevant actors, you have to follow these xx
steps shown in this code example:

### 1. Load the package

``` r
library(actordupes)
```

### 2. Generate a adjusted copy of your dataframe with “prepare_duplicate_dataframe()”

This will generate a version of your actors dataframe that contains the
lowercase names of the entities (entity_low) as well as two columns
containing the first and last names of the actors.

``` r
prepared_actors_dataframe <- prepare_duplicate_dataframe(actors_dataframe)

prepared_actors_dataframe
#>   entity_id         entity document_id     entity_low first_name last_name
#> 1         1 Philipp Müller           1 philipp müller    philipp    müller
#> 2         2    Miley Cyrus           1    miley cyrus      miley     cyrus
#> 3         3          Cyrus           1          cyrus      cyrus     cyrus
#> 4         4         Wagner           1         wagner     wagner    wagner
#> 5         5 Richard Wagner           1 richard wagner    richard    wagner
```

### 3. Mark actors that appear more than once within a document (duplicates) with “find_duplicates()”

This will add a column called “duplicate” to your initial dataframe. The
values are “TRUE” for actors who already appeared within the article and
thus are duplicates and “NA” for actors who either appear only once or,
in case of multiple appearances, at their first appearance. Note that
you can set the threshold of similarity (common strings) individually.
Values from 0 (no similarity) to 1 (full similarity) are accepted.
Typically, values of .75 or higher are set to detect duplicates in a
reliable manner. Always remember to assign the applied function to your
initial or a new dataframe to see the changes as there will be no other
output in the console.

``` r
actors_dataframe <- find_duplicates(actors_dataframe, prepared_actors_dataframe, 0.8)

actors_dataframe
#>   entity_id         entity document_id relevant duplicate
#> 1         1 Philipp Müller           1     TRUE        NA
#> 2         2    Miley Cyrus           1     TRUE        NA
#> 3         3          Cyrus           1     TRUE      TRUE
#> 4         4         Wagner           1    FALSE        NA
#> 5         5 Richard Wagner           1     TRUE      TRUE
```

### 4. Change the coding in relevant subsequent to the detection of duplicates with “mark_relevant_actors()”

If you not only wish to detect duplicates but also use this information
to identify relevant actors, it is not enough to simply filter for
actors who are not duplicates (is.na(duplicate)) as not all of them are
necessarily quoted at their first mention which will lead to a loss of
actors who are quoted at their second, third or later appearance for the
first time and therefore, are relevant. To check whether an actor that
is not quoted at their first appearance is quoted later throughout the
article, the package contains the function “mark_relevant_actors()”
which only changes the value of relevance for duplicates from TRUE to
FALSE if the actor has also been relevant at the time of his first
mention. To do so, again the similarity of names, predominantly last
names, is used to group the actors within an article.

``` r
actors_dataframe <- mark_relevant_actors(actors_dataframe, prepared_actors_dataframe, 0.8)

actors_dataframe
#> # A tibble: 5 × 5
#>   entity_id entity         document_id relevant duplicate
#>       <dbl> <chr>                <dbl> <lgl>    <lgl>    
#> 1         1 Philipp Müller           1 TRUE     NA       
#> 2         2 Miley Cyrus              1 TRUE     NA       
#> 3         3 Cyrus                    1 FALSE    TRUE     
#> 4         4 Wagner                   1 FALSE    NA       
#> 5         5 Richard Wagner           1 TRUE     TRUE
```

Note that the value in relevant for “3 = Cyrus” has been changed while
“5 = Richard Wagner” remains the same. **ATTENTION**: The
“mark_relevant_actors()” function will irreversibly change the values in
the “relevant” column of the initial dataframe. If you wish to keep it,
assign the resulting dataframe to a copy of the initial dataframe. If
you wish to have both categorisations of relevant in one dataframe, you
can subsequently join them via their corresponding entity IDs (e.g., by
using “left_join()”).
