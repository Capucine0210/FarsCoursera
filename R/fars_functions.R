globalVariables(c("MONTH","STATE","year"))
#'Make filename
#'
#'This functions insert a given year into the string accident_XXXX.csv.bz2.
#'
#'@param year numeric. Year of which the function will get the filename.
#'
#'@return A string as accident_XXXX.csv.bz2, XXXX being the input year,
#'ready to be use as a file name.
#'

make_filename <- function(year) {
  year <- as.integer(year)
  sprintf("accident_%d.csv.bz2", year) %>%
    return()
}

#'Read fars
#'
#'This functions coerce data saved as csv to a tibble object.
#'The function returns a message if the file does not exist.
#'
#'@param filename character. Path to the csv file.
#'
#'@return tibble
#'
#'@import dplyr
#'@importFrom readr read_csv
#'@importFrom tibble as_tibble
#'

fars_read <- function(filename) {
    file <- system.file("extdata",
                        filename,
                        package = "FarsCoursera")
        if(!file.exists(file)){
                stop("file '", filename, "' does not exist")}
        data <- suppressMessages({
                readr::read_csv(file)
        })
        tibble::as_tibble(data)
}


#'Fars read year
#'
#'This functions read the fars data from a given year and return a tibble with
#'month and year columns, one line by accident. The function returns an error if
#'the file for the input year is not found.
#'
#'@param years Vector of numeric or character with the year the function will
#'return the data from
#'
#'@return  A tibble by given year with 2 columns each for MONTH and year of the
#'event
#'
#'@import dplyr
#'


fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>%
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#'Fars summarize years
#'
#'This functions summarizes the monthly number of fatal accidents for the given
#'years.
#'
#'@inheritParams  fars_read_years
#'
#'@return A tibble with number of monthly accidents. Months in rows and years in
#'columns.
#'
#'@importFrom tidyr spread
#'@import dplyr
#'@import magrittr
#'
#'@export
#'
#'@examples
#'fars_summarize_years(c(2013,2014))

fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>%
                dplyr::group_by(year, MONTH) %>%
                dplyr::summarise(n = n()) %>%
                tidyr::spread(year, n)
}

#'Fars map state
#'
#'This functions plots the fatal vehicles crashes location of a given year on a
#'state map of a given state. If no crashes happened in a given year/state, the
#'function returns a message saying that there is no accident to plot.
#'
#'@param year character. The year for which the function will plot the accident.
#'@param state.num numeric. The US state to be plot.
#'
#'@return A plot showing where the accident happened for a given state in a
#'given year.
#'
#'@importFrom maps map
#'@importFrom graphics points
#'@importFrom dplyr filter
#'
#'@examples
#'fars_map_state(28,2013)
#'
#'@export

fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)


        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}
