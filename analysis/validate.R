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
library(fst)
library(progress)
library(readr)
library(tidyr)

main <- function(args = commandArgs(trailingOnly = TRUE)) {

    program_dir <- args[[1]]
    joblog_dir <- args[[2]]
    summary_dir <- args[[3]]

    validation_run_tab <- read_validation_runs(program_dir)
    joblog_tab <- read_joblogs(joblog_dir)

    run_tab <-
        validation_run_tab %>%
        left_join(joblog_tab, by = c("signature", "seq"))

    str(run_tab)

    signatures <- unique(joblog_tab$signature)
    print(signatures)

    raw_exitval_tab <-
        run_tab %>%
        select(type, package, filename, signature, exitval) %>%
        filter(signature %in% signatures) %>%
        pivot_wider(names_from = signature,
                    values_from = exitval,
                    values_fill = NA_real_)

    exitval_tab <-
        raw_exitval_tab %>%
        count(`lazy-1`,
              `lazy-2`,
               `signature+force+effect+reflection`,
               `signature+force+effect-reflection`,
               `signature+force-effect+reflection`,
               `signature+force-effect-reflection`,
               `signature-force+effect+reflection`,
               `signature-force+effect-reflection`,
               `signature-force-effect+reflection`,
               `signature-force-effect-reflection`,
               name = "count")

    raw_stdout_tab <-
        run_tab %>%
        select(type, package, filename, signature, stdout) %>%
        filter(signature %in% signatures) %>%
        pivot_wider(names_from = signature,
                    values_from = stdout,
                    values_fill = "") %>%
        mutate(`lazy-2` = `lazy-2` == `lazy-1`,
               `signature+force+effect+reflection` = `signature+force+effect+reflection` == `lazy-1`,
               `signature+force+effect-reflection` = `signature+force+effect-reflection` == `lazy-1`,
               `signature+force-effect+reflection` = `signature+force-effect+reflection` == `lazy-1`,
               `signature+force-effect-reflection` = `signature+force-effect-reflection` == `lazy-1`,
               `signature-force+effect+reflection` = `signature-force+effect+reflection` == `lazy-1`,
               `signature-force+effect-reflection` = `signature-force+effect-reflection` == `lazy-1`,
               `signature-force-effect+reflection` = `signature-force-effect+reflection` == `lazy-1`,
               `signature-force-effect-reflection` = `signature-force-effect-reflection` == `lazy-1`,
               `lazy-1` = TRUE)
    stdout_tab <-
        raw_stdout_tab %>%
        count(`lazy-1`,
              `lazy-2`,
              `signature+force+effect+reflection`,
              `signature+force+effect-reflection`,
              `signature+force-effect+reflection`,
              `signature+force-effect-reflection`,
              `signature-force+effect+reflection`,
              `signature-force+effect-reflection`,
              `signature-force-effect+reflection`,
              `signature-force-effect-reflection`,
              name = "count")

    cat("Exitcode\n")

    print(exitval_tab)

    run_tab %>%
        filter(signature %in% c("signature+force+effect+reflection", "lazy-1")) %>%
        group_by(type, package, filename) %>%
        summarize(failed = exitval[1] != exitval[2]) %>%
        ungroup() %>%
        filter(failed) %>%
        print(n = Inf)

    cat("Stdout\n")

    print(stdout_tab)

    diff_stdout <-
        raw_stdout_tab %>%
        mutate(failed = `lazy-2` == TRUE & `signature+force+effect+reflection` == FALSE) %>%
        filter(failed) %>%
        distinct(type, package, filename)

    print(diff_stdout)
    
    diff_stdout_type <-
        diff_stdout %>%
        count(type, name = "count") %>%
        print()

    print(diff_stdout_type %>% print(n = 100))

    write_fst(run_tab, path_join(c(summary_dir, "run_tab.fst")))
    write_csv(raw_exitval_tab, path_join(c(summary_dir, "exitval_raw.csv")))
    write_csv(exitval_tab, path_join(c(summary_dir, "exitval_summary.csv")))
    write_csv(raw_stdout_tab, path_join(c(summary_dir, "stdout_raw.csv")))
    write_csv(stdout_tab, path_join(c(summary_dir, "stdout_summary.csv")))

}

read_validation_runs <- function(program_dir) {
    paths <-
        list(c(program_dir, "test"),
             c(program_dir, "testthat"),
             c(program_dir, "example"),
             c(program_dir, "vignette")) %>%
        path_join() %>%
        dir_ls(recurse = 0, type = "directory") %>%
        dir_ls(recurse = 0, type = "directory") %>%
        dir_ls(recurse = 0, type = "directory")

    pb <- progress_bar$new(total = length(paths),
                           format = ":type/:package/:filename [:bar] :current/:total (:percent) eta: :eta",
                           clear = FALSE,
                           width = 120)

    read_run <- function(dirpath) {
        signature <- path_file(dirpath)
        filename <- path_file(path_dir(dirpath))
        package <- path_file(path_dir(path_dir(dirpath)))
        type <- path_file(path_dir(path_dir(path_dir(dirpath))))

        read_seq <- function(file) {
            if(file_exists(file)) {
                as.integer(str_trim(read_file(path_join(c(dirpath, "seq")))))
            }
            else {
                NA_integer_
            }
        }

        read_file_checked <- function(file) {
            if(file_exists(file)) {
                read_file(file)
            }
            else {
                NA_character_
            }
        }

        result <- tibble(dirpath = dirpath,
                         type = type,
                         package = package,
                         filename = filename,
                         signature = signature,
                         seq = read_seq(path_join(c(dirpath, "seq"))),
                         stderr = read_file_checked(path_join(c(dirpath, "stderr"))),
                         stdout = read_file_checked(path_join(c(dirpath, "stdout"))))

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
                   command = Command) %>%
            group_by(seq) %>%
            filter(row_number() == n()) %>%
            ungroup()

        str(result)

        result
    }

    joblog_files <- dir_ls(joblog_dir, recurse = 0, type = "file")

    map_dfr(joblog_files, read_joblog)
}

main()
