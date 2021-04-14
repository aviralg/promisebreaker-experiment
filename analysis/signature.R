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
    parameter_filepath <- args[[1]]
    corpus_file <- args[[2]]
    signature_dirpath <- args[[3]]

    parameters <- read_fst(parameter_filepath)
    corpus <- read_lines(corpus_file)

    parameters <- filter(parameters, pack_name %in% corpus)

    signatures <- bind_rows(make_signature(parameters, TRUE, TRUE, TRUE),
                            make_signature(parameters, TRUE, TRUE, FALSE),
                            make_signature(parameters, TRUE, FALSE, TRUE),
                            make_signature(parameters, TRUE, FALSE, FALSE),
                            make_signature(parameters, FALSE, TRUE, TRUE),
                            make_signature(parameters, FALSE, TRUE, FALSE),
                            make_signature(parameters, FALSE, FALSE, TRUE),
                            make_signature(parameters, FALSE, FALSE, FALSE))

    save_signatures <- function(signame, pack_name, content) {
        dirpath <- path_join(c(signature_dirpath, signame))
        dir_create(dirpath)

        filepath <- path_join(c(dirpath, pack_name))
        write_file(content, filepath)
    }

    pwalk(signatures, save_signatures)
}

make_signature <- function(parameters, force_lazy, effect_lazy, ref_lazy) {

    signame <- paste("signature",
                     c("-force", "+force")[force_lazy + 1],
                     c("-effect", "+effect")[effect_lazy + 1],
                     c("-reflection", "+reflection")[ref_lazy + 1],
                     sep = "")


    pb <- progress_bar$new(total = length(unique(parameters$qual_name)),
                           format = paste0(signame, " [:bar] :current/:total (:percent) eta: :eta"),
                           clear = FALSE,
                           width = 120)

    sig_tbl <-
        parameters %>%
        mutate(pack_name2 = pack_name,
               fun_name2 = fun_name) %>%
        group_by(pack_name, fun_name) %>%
        group_modify(~ {
            fun_name <- first(.x$fun_name2)
            is_base <- first(.x$pack_name2) == "base"

            indices <- .x$vararg_lazy | .x$meta_lazy

            if(force_lazy | is_base) indices <- indices | .x$force_lazy
            if(effect_lazy | is_base) indices <- indices | .x$effect_lazy
            if(ref_lazy | is_base) indices <- indices | .x$ref_lazy

            pos <- 1 + sort(.x$formal_pos[!indices])

            sig <- paste("<", paste(pos, collapse = ","), ">;", sep="")
            result <- tibble(content = paste("strict", fun_name, sig, sep = " ", collapse = "\n"))
            pb$tick(tokens = list())
            result
        }) %>%
        ungroup() %>%
        group_by(pack_name) %>%
        group_modify(~{
            tibble(content = paste(.x$content, collapse = "\n"))
        }) %>%
        ungroup() %>%
        select(pack_name, content) %>%
        add_column(signame = signame, .before = 1)

    sig_tbl
}

main()
