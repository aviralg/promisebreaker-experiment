options(dplyr.width = Inf)

library(experimentr)
library(fs)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(magrittr)
library(tibble)
library(ggplot2)
library(lazr)
library(fst)
library(progress)
library(readr)
library(tidyr)

main <- function(args = commandArgs(trailingOnly = TRUE)) {

    program_dir <- args[[1]]
    joblog_dir <- args[[2]]

    validation_run_tab <- read_validation_runs(program_dir)
    joblog_tab <- read_joblogs(joblog_dir)

    run_tab <-
        program_dir %>%
        left_join(joblog_dir, by = c("signature", "seq"))

    str(run_tab)

    signatures <- unique(run_tab$signature)

    status_tab <-
        run_tab %>%
        select(type, package, filename, signature, exitval) %>%
        pivot_wider(names_from = signature,
                    values_from = exitval,
                    values_fill = NA_real_) %>%
        filter(
            across(
                .cols = signatures,
                .fns = ~ !is.na(.x)
            )
        ) %>%
        select(-type, -package, -filename) %>%
        count(everything(), name = "count")


    print(status_tab)

}

read_validation_runs <- function(program_dir) {
    paths <-
        list(c(program_dirpath, "test"),
             c(program_dirpath, "testthat"),
             c(program_dirpath, "example"),
             c(program_dirpath, "vignette")) %>%
        path_join() %>%
        dir_ls(recurse = 0, type = "directory") %>%
        dir_ls(recurse = 0, type = "directory") %>%
        dir_ls(recurse = 0, type = "directory")

    pb <- progress_bar$new(total = length(paths),
                           format = ":type/:package/:filename [:bar] :current/:total (:percent) eta: :eta",
                           clear = FALSE,
                           width = 80)

    read_run <- function(dirpath) {
        signature <- path_file(dirpath)
        filename <- path_file(path_dir(filepath))
        package <- path_file(path_dir(path_dir(filepath)))
        type <- path_file(path_dir(path_dir(path_dir(filepath))))

        result <- tibble(dirpath = dirpath,
                         type = type,
                         package = package,
                         filename = filename,
                         signature = signature,
                         seq = as.integer(str_trim(read_file(path_join(c(dirpath, "seq"))))),
                         stderr = read_file(path_join(c(dirpath, "stderr"))),
                         stdout = read_file(path_join(c(dirpath, "stdout"))))

        pb$tick(tokens = list(type = type, package = package, filename = filename))

        result
    }

    filepaths <- map_dfr(paths, read_run)
}


read_joblogs <- function(joblog_dir) {

    read_joblog <- function(filepath) {
        signature <- path_file(filepath)

        result <-
            read_delim(filepath, delim="\t") %>%
            add_column(signature = signature, .before=1) %>%
            mutate(JobRuntime = as.double(str_trim(JobRuntime))) %>%
            mutate(Seq = as.integer(Seq)) %>%
            rename(seq = Seq,
                   host = Host,
                   start_time = Starttime,
                   job_runtime = JobRuntime,
                   send = Send,
                   receive = Receive,
                   exitval = Exitval,
                   signal = Signal,
                   command = Command)

        result
    }

    joblog_files <- dir_ls(path_join, recurse = 0, type = "file")

    map_dfr(joblog_files, read_joblog)
}

main()
