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

NAME_SEPARATOR = "*$#$*"
STEPS <- c("reduce", "combine", "summarize")

main <- function(args = commandArgs(trailingOnly = TRUE)) {
    step <- args[[1]]

    if(!(step %in% STEPS)) {
        stop(sprintf("unexpected step %s", step), call. = TRUE)
    }

    input_path <- args[[2]]

    if(!is_dir(input_path)) {
        stop(sprintf("path %s is not a directory", input_path), call. = TRUE)
    }

    output_path <- args[[3]]

    analyses <- as.character(unlist(args[4:length(args)]))

    for(analysis in analyses) {
        apply_analysis(step, input_path, output_path, analysis)
    }
}


apply_analysis <- function(step, input_path, output_path, analysis) {
    if(step == "combine") {
        result <- combine_analysis(input_path, analysis)
    }
    else if (step %in% c("reduce", "summarize")) {
        data <- dir_as_env(input_path, lazy = TRUE)
        fun_name <- paste0(step, "_", analysis)
        result <- do.call(fun_name, list(data))
    }
    write_analysis(result, output_path)
}

write_analysis <- function(data, dirpath) {
    for(name in names(data)) {
        filepath <- path_join(c(dirpath, name))
        dir_create(path_dir(filepath))
        value <- data[[name]]
        if(is.data.frame(value)) {
            write_fst(value, path_ext_set(filepath, "fst"))
        }
        else {
            write_file(value, filepath)
        }
    }
}


combine_analysis <- function(input_path, analysis) {
    paths <-
        list(c(input_path, "test"),
             c(input_path, "testthat"),
             c(input_path, "example"),
             c(input_path, "vignette")) %>%
        path_join() %>%
        dir_ls(recurse = 0, type = "directory") %>%
        dir_ls(recurse = 0, type = "directory")

    pb <- progress_bar$new(total = length(paths),
                           format = ":type/:package/:filename [:bar] :current/:total (:percent) eta: :eta",
                           clear = FALSE,
                           width = 80)

    make_filepath <- function(path) {
        filepath <-
            c(path, "reduce", analysis) %>%
            path_join() %>%
            path_ext_set(".fst")

        filepath
    }

    read_df <- function(filepath) {
        filename <- path_file(path_dir(path_dir(filepath)))
        package <- path_file(path_dir(path_dir(path_dir(filepath))))
        type <- path_file(path_dir(path_dir(path_dir(path_dir(filepath)))))

        pb$tick(tokens = list(type = type, package = package, filename = filename))

        df <- read_fst(filepath) %>%
            add_column(type = type,
                       package = package,
                       filename = filename,
                       .before = 1)
    }

    filepaths <- keep(map_chr(paths, make_filepath), file_exists)
    setNames(list(map_dfr(filepaths, read_df)), analysis)
}


################################################################################
## HELPERS
################################################################################

add_cum_perc <- function(df) {
    df %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count / sum(count) * 100, 2)) %>%
        mutate(cum_count = cumsum(count)) %>%
        mutate(cum_perc = round(cum_count / sum(count) * 100, 2))
}

################################################################################
## UNEVALUATED
################################################################################

reduce_unevaluated <- function(data) {
    arguments <- data$output$arguments
    functions <- data$output$functions
    calls <- data$output$calls

    unevaluated <-
        arguments %>%
        filter(!vararg & !missing) %>%
        filter(cap_force + esc_force == 0) %>%
        left_join(select(functions, qual_name, anonymous, fun_id), by = "fun_id") %>%
        filter(!anonymous) %>%
        select(qual_name, formal_pos, arg_name, default_arg, fun_def, call_id) %>%
        left_join(select(calls, call_id, call_expr), by = "call_id") %>%
        select(-call_id) %>%
        count(qual_name, formal_pos, arg_name, default_arg, fun_def, call_expr, name = "arg_count")

    list(unevaluated = unevaluated)
}

summarize_unevaluated <- function(data) {

    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    parameters <-
        data$arguments %>%
        group_by(qual_name, anonymous, formal_pos) %>%
        summarize(arg_name = first(arg_name),
                  vararg = first(vararg),
                  missing = sum(missing),
                  call_count = sum(call_count),
                  ## escaped
                  escaped = sum(escaped),
                  ## force
                  force_tot = sum(force_tot),
                  force_cap = sum(force_cap),
                  force_esc = sum(force_esc),
                  force_con = sum(force_con),
                  ## lookup
                  lookup_tot = sum(lookup_tot),
                  lookup_cap = sum(lookup_cap),
                  lookup_esc = sum(lookup_esc),
                  lookup_con = sum(lookup_con),
                  ## meta
                  meta_tot = sum(meta_tot),
                  meta_cap = sum(meta_cap),
                  meta_esc = sum(meta_esc),
                  ## assign
                  assign_self  = sum(assign_self),
                  assign_tot = sum(assign_tot),
                  ## define
                  define_self  = sum(define_self),
                  define_tot = sum(define_tot),
                  ## remove
                  remove_self  = sum(remove_self),
                  remove_tot = sum(remove_tot),
                  ## error
                  error_self  = sum(error_self),
                  error_tot = sum(error_tot),
                  ## lookup
                  lookup_self  = sum(lookup_self),
                  lookup_tot = sum(lookup_tot),
                  ## as.environment
                  as_env_self = sum(as_env_self),
                  as_env_tot = sum(as_env_tot),
                  ## as.environment
                  pos_env_self = sum(pos_env_self),
                  pos_env_tot = sum(pos_env_tot)) %>%
        ungroup() %>%
        mutate(pack_name = unlist(map(str_split(qual_name, fixed(NAME_SEPARATOR)), ~.[1]))) %>%
        mutate(fun_name = unlist(map(str_split(qual_name, fixed(NAME_SEPARATOR)), splitter))) %>%
        mutate(outer = unlist(map(str_split(qual_name, fixed(NAME_SEPARATOR)), length)) == 2) %>%
        ## filter functions that are top-level and not anonymous
        filter(pack_name != "<NA>" & outer & !anonymous) %>%
        mutate(vararg_lazy = as.logical(vararg),
               force_lazy = force_tot != call_count,
               meta_lazy = meta_tot != 0,

               assign_lazy  = assign_tot != 0,
               define_lazy  = define_tot != 0,
               remove_lazy = remove_tot != 0,
               error_lazy = error_tot != 0,
               lookup_lazy = lookup_tot != 0,
               effect_lazy = assign_lazy | define_lazy | remove_lazy | error_lazy | lookup_lazy,

               as_env_lazy = as_env_tot != 0,
               pos_env_lazy = pos_env_tot != 0,
               ref_lazy = as_env_lazy | pos_env_lazy)

    laziness <-
        parameters %>%
        count(vararg_lazy, force_lazy, meta_lazy, effect_lazy, ref_lazy, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2)) %>%
        mutate(cum_perc = cumsum(perc))

    list(parameters = parameters)
}

################################################################################
## ARGUMENTS
################################################################################

reduce_arguments <- function(data) {
    arguments <- data$output$arguments
    functions <- data$output$functions

    has_pattern <- function(seq, pattern) {
        as.logical(str_count(seq, pattern))
    }

    ## for every parameter position, we want the following bits of information:
    ## - arg_name
    ## - vararg
    ## - missing (overall, esc, cap)
    ## - force (overall, esc, cap)
    ## - meta (overall, esc, cap)
    ## - lookup (overall, esc, cap)
    ## - assign (self, ref)
    ## - define (self, ref)
    ## - lookup (self, ref)
    ## - remove (self, ref)
    ## - error (self, ref)
    ## - as_environment (self, ref)
    ## - pos_to_env (self, ref)
    ## - con_force
    ## - con_lookup
    arguments <-
        arguments %>%
        mutate(not_promise = arg_type != "promise" & arg_type != "missing" & arg_type != "vararg") %>%
        mutate(cap_force = cap_force + preforced + not_promise) %>%
        mutate(force_tot = cap_force + esc_force,
               meta_tot = cap_meta + esc_meta,
               lookup_tot = cap_lookup + esc_lookup) %>%
        left_join(select(functions, qual_name, anonymous, fun_id), by = "fun_id") %>%
        group_by(qual_name, anonymous, formal_pos) %>%
        summarize(arg_name = first(arg_name),
                  vararg = first(vararg),
                  missing = sum(as.logical(missing)),
                  call_count = n(),
                  ## escaped
                  escaped = sum(as.logical(escaped)),
                  ## force
                  force_tot = sum(as.logical(force_tot)),
                  force_cap = sum(as.logical(cap_force)),
                  force_esc = sum(as.logical(esc_force)),
                  force_con = sum(as.logical(con_force)),
                  ## lookup
                  lookup_tot = sum(as.logical(lookup_tot)),
                  lookup_cap = sum(as.logical(cap_lookup)),
                  lookup_esc = sum(as.logical(esc_lookup)),
                  lookup_con = sum(as.logical(con_lookup)),
                  ## meta
                  meta_tot = sum(as.logical(meta_tot)),
                  meta_cap = sum(as.logical(cap_meta)),
                  meta_esc = sum(as.logical(esc_meta)),
                  ## assign
                  assign_self  = sum(has_pattern(self_effect_seq, fixed("A"))),
                  assign_tot = sum(has_pattern(effect_seq, fixed("A"))),
                  ## define
                  define_self  = sum(has_pattern(self_effect_seq, fixed("D"))),
                  define_tot = sum(has_pattern(effect_seq, fixed("D"))),
                  ## remove
                  remove_self  = sum(has_pattern(self_effect_seq, fixed("R"))),
                  remove_tot = sum(has_pattern(effect_seq, fixed("R"))),
                  ## error
                  error_self  = sum(has_pattern(self_effect_seq, fixed("E"))),
                  error_tot = sum(has_pattern(effect_seq, fixed("E"))),
                  ## lookup
                  lookup_self  = sum(has_pattern(self_effect_seq, fixed("L"))),
                  lookup_tot = sum(has_pattern(effect_seq, fixed("L"))),
                  ## as.environment
                  as_env_self = sum(has_pattern(self_ref_seq, fixed("as.environment"))),
                  as_env_tot = sum(has_pattern(ref_seq, fixed("as.environment"))),
                  ## as.environment
                  pos_env_self = sum(has_pattern(self_ref_seq, fixed("pos.to.env"))),
                  pos_env_tot = sum(has_pattern(ref_seq, fixed("pos.to.env")))) %>%
        ungroup()

    list(arguments = arguments)

}

summarize_arguments <- function(data) {

    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    parameters <-
        data$arguments %>%
        group_by(qual_name, anonymous, formal_pos) %>%
        summarize(arg_name = first(arg_name),
                  vararg = first(vararg),
                  missing = sum(missing),
                  call_count = sum(call_count),
                  ## escaped
                  escaped = sum(escaped),
                  ## force
                  force_tot = sum(force_tot),
                  force_cap = sum(force_cap),
                  force_esc = sum(force_esc),
                  force_con = sum(force_con),
                  ## lookup
                  lookup_tot = sum(lookup_tot),
                  lookup_cap = sum(lookup_cap),
                  lookup_esc = sum(lookup_esc),
                  lookup_con = sum(lookup_con),
                  ## meta
                  meta_tot = sum(meta_tot),
                  meta_cap = sum(meta_cap),
                  meta_esc = sum(meta_esc),
                  ## assign
                  assign_self  = sum(assign_self),
                  assign_tot = sum(assign_tot),
                  ## define
                  define_self  = sum(define_self),
                  define_tot = sum(define_tot),
                  ## remove
                  remove_self  = sum(remove_self),
                  remove_tot = sum(remove_tot),
                  ## error
                  error_self  = sum(error_self),
                  error_tot = sum(error_tot),
                  ## lookup
                  lookup_self  = sum(lookup_self),
                  lookup_tot = sum(lookup_tot),
                  ## as.environment
                  as_env_self = sum(as_env_self),
                  as_env_tot = sum(as_env_tot),
                  ## as.environment
                  pos_env_self = sum(pos_env_self),
                  pos_env_tot = sum(pos_env_tot)) %>%
        ungroup() %>%
        mutate(pack_name = unlist(map(str_split(qual_name, fixed(NAME_SEPARATOR)), ~.[1]))) %>%
        mutate(fun_name = unlist(map(str_split(qual_name, fixed(NAME_SEPARATOR)), splitter))) %>%
        mutate(outer = unlist(map(str_split(qual_name, fixed(NAME_SEPARATOR)), length)) == 2) %>%
        ## filter functions that are top-level and not anonymous
        filter(pack_name != "<NA>" & outer & !anonymous) %>%
        mutate(vararg_lazy = as.logical(vararg),
               force_lazy = force_tot != call_count,
               meta_lazy = meta_tot != 0,

               assign_lazy  = assign_tot != 0,
               define_lazy  = define_tot != 0,
               remove_lazy = remove_tot != 0,
               error_lazy = error_tot != 0,
               lookup_lazy = lookup_tot != 0,
               effect_lazy = assign_lazy | define_lazy | remove_lazy | error_lazy | lookup_lazy,

               as_env_lazy = as_env_tot != 0,
               pos_env_lazy = pos_env_tot != 0,
               ref_lazy = as_env_lazy | pos_env_lazy)

    list(parameters = parameters)
}

################################################################################
## FUNCTIONS
################################################################################

reduce_functions <- function(data) {
    functions <- data$output$functions

    list(functions = functions)
}

summarize_functions <- function(data) {
    functions <- data$functions

    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    name_split <- str_split(functions$qual_name, fixed(NAME_SEPARATOR))
    functions %<>%
        mutate(pack_name = map_chr(name_split, ~.[1])) %>%
        mutate(fun_name = map_chr(name_split, splitter)) %>%
        mutate(outer = map_int(name_split, length) == 2) %>%
        filter(!anonymous & outer & pack_name != "<NA>") %>%
        group_by(pack_name, fun_name, qual_name) %>%
        summarize(fun_hash = first(fun_hash),
                  fun_def = first(fun_def),
                  call_count = sum(call_count)) %>%
        ungroup()

    list(functions = functions)
}

################################################################################
## METAPROGRAMMING
################################################################################

reduce_metaprogramming <- function(data) {
    arguments <- data$output$arguments
    functions <- data$output$functions
    metaprogramming <- data$output$metaprogramming

    meta_summary <-
        arguments %>%
        filter(vararg == 0) %>%
        select(fun_id, formal_pos, cap_meta, esc_meta) %>%
        mutate(meta = cap_meta + esc_meta) %>%
        filter(meta != 0) %>%
        left_join(functions, by = "fun_id") %>%
        filter(!is.na(qual_name)) %>%
        group_by(qual_name, formal_pos) %>%
        summarize(arg_count = n(),
                  meta_count = sum(meta),
                  min_meta = min(meta),
                  max_meta = max(meta))

    meta_depth <-
        metaprogramming %>%
        select(meta_type, sink_fun_id, source_fun_id, source_formal_pos, depth) %>%
        left_join(select(functions, fun_id, sink_qual_name = qual_name), by = c("sink_fun_id" = "fun_id")) %>%
        left_join(select(functions, fun_id, source_qual_name = qual_name), by = c("source_fun_id" = "fun_id")) %>%
        count(meta_type, sink_qual_name, source_qual_name, source_formal_pos, depth, name = "count") %>%
        select(meta_type, sink_qual_name, source_qual_name, source_formal_pos, depth, count)

    list(meta_summary = meta_summary, meta_depth = meta_depth)
}


combine_metaprogramming <- function(reduce) {

}

################################################################################
## REFLECTION
################################################################################

reduce_reflection <- function(data) {

    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, anonymous)
    arg_ref <- data$output$arg_ref
    calls <- select(data$output$calls, call_id, call_expr)

    arguments <-
        arguments %>%
        filter(vararg == 0 & missing == 0) %>%
        select(arg_id, force_depth, default, self_ref_seq, ref_seq)

    arg_ref <-
        arg_ref %>%
        left_join(functions, by = c("source_fun_id" = "fun_id"))%>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(calls, by = c("source_call_id" = "call_id")) %>%
        left_join(arguments, by = c("source_arg_id" = "arg_id")) %>%
        select(-source_arg_id, -source_fun_id, -source_call_id, -anonymous) %>%
        rename(source_qual_name = qual_name,
               source_call_expr = call_expr,
               source_self_ref_seq = self_ref_seq,
               source_ref_seq = ref_seq,
               source_force_depth = force_depth,
               source_default = default) %>%
        left_join(functions, by = "fun_id") %>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(calls, by = "call_id") %>%
        left_join(arguments, by = "arg_id") %>%
        select(-arg_id, -fun_id, -call_id, -anonymous)

    str(arg_ref %>% filter(!transitive))

    list(arg_ref = arg_ref)
}

summarize_reflection <- function(data) {

    arg_ref <- data$arg_ref

    str(arg_ref)

    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    arg_ref <-
        data$arg_ref %>%
        mutate(backtrace = str_replace_all(backtrace, "id = [0-9]+", "id = <id>")) %>%
        count(ref_type, transitive,
              source_qual_name, source_formal_pos, source_call_expr, source_force_depth,
              source_self_ref_seq, source_ref_seq, source_force_depth, source_default,
              qual_name, formal_pos, call_expr, force_depth,
              self_ref_seq, ref_seq, force_depth, default, backtrace,
              name = "count")

    split_names <- str_split(arg_ref$qual_name, fixed(NAME_SEPARATOR))
    pack_name <- map_chr(split_names, ~.[1])
    fun_name <- map_chr(split_names, splitter)
    outer <- map_int(split_names, length) == 2

    arg_ref <-
        arg_ref %>%
        mutate(pack_name = pack_name,
               fun_name = fun_name,
               outer = outer) %>%
        filter(pack_name != "<NA>" & outer) %>%
        select(-qual_name, -outer)

    transitive_arg_ref <- filter(arg_ref, transitive)

    direct_arg_ref <- filter(arg_ref, !transitive)

    source_split_names <- str_split(transitive_arg_ref$source_qual_name, fixed(NAME_SEPARATOR))
    source_pack_name <- map_chr(source_split_names, ~.[1])
    source_fun_name <- map_chr(source_split_names, splitter)
    source_outer <- map_int(source_split_names, length) == 2

    transitive_arg_ref <-
        transitive_arg_ref %>%
        mutate(source_pack_name = source_pack_name,
               source_fun_name = source_fun_name,
               source_outer = source_outer) %>%
        filter(source_pack_name != "<NA>" & source_outer) %>%
        select(-source_qual_name, -source_outer)

    arg_ref <- bind_rows(direct_arg_ref, transitive_arg_ref)

    str(arg_ref)

    list(arg_ref = arg_ref)
}

################################################################################
## EFFECTS
################################################################################

## how many promises do side effects? compare against total promises
## how many promises do side effects transitively.
## show promise effect sequence table
## how many parameters do effects? cmpare against total parameters
## how many functions do effects? compare against total functions
## how many lookups, how many reads? compare against total reads and reads
## chain length that makes everything lazy (in terms of promises and parameters)
## look at examples of that chain and figure out why they are lazy
## how many functions have arguments that both read and write (same variable?)
reduce_effects <- function(data) {
    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, fun_hash, fun_def)
    effects <- data$output$effects
    calls <- data$output$calls

    arg_effect_summary <-
        arguments %>%
        filter(vararg == 0) %>%
        count(fun_id, formal_pos, effect_seq, self_effect_seq, name = "count") %>%
        left_join(functions, by = "fun_id") %>%
        count(qual_name, fun_hash, fun_def,
              formal_pos, effect_seq, self_effect_seq,
              wt = count, name = "arg_count") ## %>%
    ##print(n = Inf, width = Inf)

    effects %>%
        count(transitive, type, name = "count") %>%
        arrange(transitive, desc(count)) %>%
        print()

    effects %>%
        filter(!transitive) %>%
        distinct(type, arg_id) %>%
        count(type, name = "count") %>%
        arrange(desc(count)) %>%
        print()

    effects %>%
        filter(transitive) %>%
        distinct(type, arg_id) %>%
        count(type, name = "count") %>%
        arrange(desc(count)) %>%
        print()

    arguments %>%
        filter(self_effect_seq != "") %>%
        mutate(self_effect_seq = run_length_encoding(self_effect_seq)) %>%
        count(self_effect_seq, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        mutate(self_effect_seq = str_trunc(self_effect_seq, 20)) %>%
        print()

    arguments %>%
        filter(effect_seq != "") %>%
        mutate(effect_seq = run_length_encoding(effect_seq)) %>%
        count(effect_seq, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        mutate(effect_seq = str_trunc(effect_seq, 20)) %>%
        print()

    cat("******************************** laziness propagation **********************\n")
    effects %>%
        select(source_fun_id, source_call_id, source_formal_pos, fun_id, formal_pos) %>%
        filter(!is.na(source_fun_id)) %>%
        left_join(functions, by = c("source_fun_id" = "fun_id")) %>%
        left_join(select(calls, call_id, call_expr), by = c("source_call_id"= "call_id")) %>%
        select(source_qual_name = qual_name, source_formal_pos, fun_id, formal_pos, call_expr) %>%
        left_join(functions, by = c("fun_id" = "fun_id")) %>%
        distinct(source_qual_name, source_formal_pos, qual_name, formal_pos, call_expr) %>%
        count(source_qual_name, source_formal_pos, call_expr, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        select(source_qual_name, source_formal_pos, count, perc, cum_perc, call_expr) %>%
        print()

    cat("******************************** sys.function **********************\n")
    effects %>%
        filter(!is.na(source_call_id)) %>%
        select(type, source_fun_id, source_call_id, source_formal_pos, fun_id, formal_pos, backtrace) %>%
        filter(!is.na(source_fun_id)) %>%
        left_join(functions, by = c("source_fun_id" = "fun_id")) %>%
        left_join(select(calls, call_id, call_expr), by = c("source_call_id"= "call_id")) %>%
        select(type, source_qual_name = qual_name, source_formal_pos, fun_id, formal_pos, call_expr, backtrace) %>%
        left_join(functions, by = c("fun_id" = "fun_id")) %>%
        distinct(type, source_qual_name, source_formal_pos, qual_name, formal_pos, call_expr, backtrace) %>%
        filter(source_qual_name == "base*$#$*namespaceImportFrom") %>%
        print()

    effects %>%
        filter(is.na(source_call_id)) %>%
        select(type, fun_id, call_id, formal_pos, backtrace) %>%
        left_join(functions, by = c("fun_id" = "fun_id")) %>%
        left_join(select(calls, call_id, call_expr), by = c("call_id"= "call_id")) %>%
        select(type, qual_name, formal_pos, call_expr, backtrace) %>%
        filter(qual_name == "base*$#$*namespaceImportFrom") %>%
        print()


    cat("******************************** WRITES **********************\n")
    effects %>%
        filter(!transitive, type != 'L') %>%
        left_join(functions, by = c("fun_id" = "fun_id")) %>%
        left_join(select(calls, call_id, call_expr), by = "call_id") %>%
        count(qual_name, formal_pos, call_expr, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        select(qual_name, formal_pos, count, perc, cum_perc, call_expr) %>%
        print()

    cat("******************************** READS **********************\n")
    effects %>%
        filter(!transitive, type == 'L') %>%
        left_join(functions, by = c("fun_id" = "fun_id")) %>%
        left_join(select(calls, call_id, call_expr), by = "call_id") %>%
        count(qual_name, formal_pos, call_expr, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        select(qual_name, formal_pos, count, perc, cum_perc, call_expr) %>%
        print()

    ##effects %>%
    ##    filter(!transitive, type == 'L') %>%
    ##    left_join(functions, by = c("fun_id" = "fun_id")) %>%
    ##    left_join(select(calls, call_id, call_expr), by = "call_id") %>%
    ##    count(var_name, qual_name, formal_pos, call_expr, name = "count") %>%
    ##    arrange(desc(count)) %>%
    ##    mutate(perc = round(count * 100 / sum(count), 2),
    ##           cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
    ##    print()
    ##
    ##effects %>%
    ##    filter(var_name == "vec_duplicate_any") %>%
    ##    print()

    ##    effects <-
    ##        effects %>%
    ##        left_join(functions, by = c("source_fun_id" = "fun_id")) %>%
    ##        group_by(type, var_name, qual_name, source_formal_pos) %>%
    ##        summarize(fun_id)
    ##        arrange(desc(count)) %>%
    ##        mutate(perc = round(count * 100 / sum(count), 2),
    ##               cum_perc = round(100 * cumsum(count)/sum(count), 2))
    ##        #print(n = Inf, width = Inf)


    list(arg_effect_summary = arg_effect_summary, effects = effects)
}

reduce_effects <- function(data) {

    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, anonymous)
    calls <- select(data$output$calls, call_id, call_expr)
    effects <- data$output$effects

    arguments <-
        arguments %>%
        filter(vararg == 0 & missing == 0) %>%
        select(arg_id, force_depth, default, self_effect_seq, effect_seq, arg_type, expr_type)

    str(effects)

    effects <-
        effects %>%
        left_join(functions, by = c("source_fun_id" = "fun_id"))%>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(calls, by = c("source_call_id" = "call_id")) %>%
        left_join(arguments, by = c("source_arg_id" = "arg_id")) %>%
        select(-source_arg_id, -source_fun_id, -source_call_id, -anonymous) %>%
        rename(source_qual_name = qual_name,
               source_call_expr = call_expr,
               source_self_effect_seq = self_effect_seq,
               source_effect_seq = effect_seq,
               source_force_depth = force_depth,
               source_default = default,
               source_arg_type = arg_type,
               source_expr_type = expr_type) %>%
        left_join(functions, by = "fun_id") %>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(calls, by = "call_id") %>%
        left_join(arguments, by = "arg_id") %>%
        select(-fun_id, -call_id, -anonymous) %>%
        mutate(backtrace = str_replace_all(backtrace, "id = [0-9]+", "id = <id>")) %>%
        group_by(type, var_name, transitive, source_formal_pos,
                 formal_pos, backtrace, source_qual_name, source_call_expr,
                 source_force_depth, source_default, source_self_effect_seq,
                 source_effect_seq, qual_name, call_expr, force_depth,
                 default, self_effect_seq, effect_seq, source_arg_type,
                 source_expr_type, arg_type, expr_type) %>%
        summarize(argument_count = length(unique(arg_id)),
                  operation_count = n()) %>%
        ungroup()

    str(effects %>% filter(!transitive))

    list(effects = effects)
}

summarize_effects <- function(data) {
    effects <- data$effects

    print(str(effects))

    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    print("here 1")
    effects <-
        effects %>%
        group_by(type, var_name, transitive, source_formal_pos,
                 formal_pos, backtrace, source_qual_name, source_call_expr,
                 source_force_depth, source_default, source_self_effect_seq,
                 source_effect_seq, qual_name, call_expr, force_depth,
                 default, self_effect_seq, effect_seq, source_arg_type,
                 source_expr_type, arg_type, expr_type) %>%
        summarize(argument_count = sum(argument_count),
                  operation_count = sum(operation_count)) %>%
        ungroup()

    split_names <- str_split(effects$qual_name, fixed(NAME_SEPARATOR))
    pack_name <- map_chr(split_names, ~.[1])
    fun_name <- map_chr(split_names, splitter)
    outer <- map_int(split_names, length) == 2

    effects <-
        effects %>%
        mutate(pack_name = pack_name,
               fun_name = fun_name,
               outer = outer) %>%
        filter(pack_name != "<NA>" & outer) %>%
        select(-qual_name, -outer)

    transitive_effects <- filter(effects, transitive)

    direct_effects <- filter(effects, !transitive)

    source_split_names <- str_split(transitive_effects$source_qual_name, fixed(NAME_SEPARATOR))
    source_pack_name <- map_chr(source_split_names, ~.[1])
    source_fun_name <- map_chr(source_split_names, splitter)
    source_outer <- map_int(source_split_names, length) == 2

    transitive_effects <-
        transitive_effects %>%
        mutate(source_pack_name = source_pack_name,
               source_fun_name = source_fun_name,
               source_outer = source_outer) %>%
        filter(source_pack_name != "<NA>" & source_outer) %>%
        select(-source_qual_name, -source_outer)
    print("here 8")
    effects <- bind_rows(direct_effects, transitive_effects)

    str(effects)

    list(effects = effects)
}

################################################################################
## ESCAPED
################################################################################

## how many promises escape
## how many parameters escape
## how many functions have escaped arguments
## are they forced before or after escape
## do they do side effects
## do they do reflection
reduce_escaped <- function(data) {
    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, fun_hash, fun_def)
    effects <- data$output$effects
    calls <- data$output$calls

    ## how many promises escape
    escaped_arguments <-
        arguments %>%
        filter(escaped != 0) %>%
        left_join(functions, by = "fun_id")

    cat("Number of escaped arguments:", nrow(escaped_arguments), "\n")

    ## how many parameter positions
    escaped_params <-
        escaped_arguments %>%
        distinct(qual_name, formal_pos, fun_def)

    cat("Number of escaped parameters:", nrow(escaped_params), "\n")

    ## how many functions
    escaped_funs <-
        escaped_params %>%
        distinct(qual_name, fun_def)

    cat("Number of escaped functions:", nrow(escaped_funs), "\n")

    ## are escaped arguments forced after escape
    escaped_arguments %>%
        mutate(cap_force = as.logical(cap_force),
               cap_meta = as.logical(cap_meta),
               cap_lookup = as.logical(cap_lookup),
               esc_force = as.logical(esc_force),
               esc_meta = as.logical(esc_meta),
               esc_lookup = as.logical(esc_lookup)) %>%
        count(cap_force, cap_meta, cap_lookup,
              esc_force, esc_meta, esc_lookup, name = "count") %>%
        print()

    arguments %>%
        filter(escaped != 0) %>%
        count(event_seq, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        print()

    arguments %>%
        filter(escaped != 0) %>%
        count(event_seq, self_effect_seq, name = "count") %>%
        arrange(desc(count)) %>%
        mutate(perc = round(count * 100 / sum(count), 2),
               cum_perc = round(100 * cumsum(count)/sum(count), 2)) %>%
        print()

### effect sequence not empty
    arguments %>%
        filter(escaped != 0) %>%
        left_join(functions, by = "fun_id") %>%
        select(qual_name, formal_pos, event_seq, self_effect_seq) %>%
        print()
}

summarize_escaped <- function(data) {
}

################################################################################
## TOTAL
################################################################################

reduce_total <- function(data) {
    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, fun_hash, fun_def)
    effects <- data$output$effects
    calls <- data$output$calls

    arguments %>%
        filter(default == TRUE) %>%
        select(call_id, arg_name, formal_pos) %>%
        left_join(calls, by = "call_id") %>%
        distinct(arg_name, formal_pos, call_expr) %>%
        slice(1:20) %>%
        print()
}

summarize_total <- function(data) {
}



reduce_error <- function(data) {
    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, fun_hash, fun_def)
    effects <- data$output$effects
    calls <- data$output$calls

    arguments %>%
        filter(self_effect_seq != "") %>%
        filter(str_count(self_effect_seq, "E") != 0) %>%
        print()

    effects %>%
        filter(type == "E") %>%
        print()
}

################################################################################
## DIRECT EFFECTS
################################################################################

simplify_effect_seq <- function(seq) {
    seq %>%
        str_replace_all("[L]+", "L+") %>%
        str_replace_all("[A]+", "A+") %>%
        str_replace_all("[D]+", "D+") %>%
        str_replace_all("[R]+", "R+")
}


reduce_direct_effects <- function(data) {
    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, anonymous)

    direct_effects <-
        arguments %>%
        filter(vararg == 0 & missing == 0) %>%
        filter(!is.na(self_effect_seq) & self_effect_seq != "") %>%
        select(arg_id, fun_id, formal_pos, force_pos, arg_type, expr_type, val_type, self_effect_seq) %>%
        left_join(functions, by = "fun_id") %>%
        filter(!anonymous) %>%
        mutate(simplified_effect_seq = simplify_effect_seq(self_effect_seq),
               lookup_count = str_count(self_effect_seq, "L"),
               assign_count = str_count(self_effect_seq, "A"),
               define_count = str_count(self_effect_seq, "D"),
               remove_count = str_count(self_effect_seq, "R"),
               error_count  = str_count(self_effect_seq, "E")) %>%
        group_by(qual_name, formal_pos, force_pos, arg_type, expr_type, val_type, simplified_effect_seq) %>%
        summarize(argument_count = n(),
                  lookup_count = sum(lookup_count),
                  assign_count = sum(assign_count),
                  define_count = sum(define_count),
                  remove_count = sum(remove_count),
                  error_count  = sum(error_count)) %>%
        ungroup()

    list(direct_effects = direct_effects)
}

summarize_direct_effects <- function(output) {

    direct_effects <- output$direct_effects

    direct_effects <-
        direct_effects %>%
        group_by(qual_name, formal_pos, force_pos, arg_type, expr_type, val_type, simplified_effect_seq) %>%
        summarize(argument_count = sum(argument_count),
                  lookup_count = sum(lookup_count),
                  assign_count = sum(assign_count),
                  define_count = sum(define_count),
                  remove_count = sum(remove_count),
                  error_count  = sum(error_count)) %>%
        ungroup()



    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    split_names <- str_split(direct_effects$qual_name, fixed(NAME_SEPARATOR))
    pack_name <- map_chr(split_names, ~.[1])
    fun_name <- map_chr(split_names, splitter)
    outer <- map_int(split_names, length) == 2

    direct_effects <-
        direct_effects %>%
        mutate(pack_name = pack_name,
               fun_name = fun_name,
               outer = outer) %>%
        filter(pack_name != "<NA>" & outer) %>%
        select(-qual_name, -outer)

    list(direct_effects = direct_effects)
}

################################################################################
## STATISTICS
################################################################################

reduce_statistics <- function(data) {
    list(allocation = data$statistics$allocation,
         execution = data$statistics$execution)
}

summarize_statistics <- function(output) {
    allocation <- output$allocation
    execution <- output$execution

    allocation <-
        allocation %>%
        group_by(type) %>%
        summarize(size = first(size),
                  allocated = sum(allocated),
                  deallocated = sum(deallocated),
                  finalized = sum(finalized),
                  max_alive = sum(max_alive),
                  zombie = sum(zombie)) %>%
        ungroup()

    execution <-
        execution %>%
        group_by(exec) %>%
        summarize(total_time = sum(total_time),
                  execution_count = sum(execution_count),
                  average_time = total_time / execution_count,
                  minimum_time = min(minimum_time),
                  maximum_time = max(maximum_time)) %>%
        ungroup()

    list(allocation = allocation, execution = execution)
}

################################################################################
## ARGUMENT TYPE
################################################################################

reduce_argument_type <- function(data) {

    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, anonymous)

    argument_type <-
        arguments %>%
        filter(vararg == 0 & missing == 0) %>%
        count(fun_id, formal_pos, arg_type, expr_type, val_type, name = "argument_count") %>%
        left_join(functions, by = "fun_id") %>%
        filter(!anonymous) %>%
        select(-anonymous, -fun_id)

    list(argument_type)
}

summarize_argument_type <- function(output) {
    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    argument_type <-
        output$argument_type %>%
        count(qual_name, formal_pos, arg_type, expr_type, val_type, wt = argument_count, name = "argument_count")

    split_names <- str_split(argument_type$qual_name, fixed(NAME_SEPARATOR))
    pack_name <- map_chr(split_names, ~.[1])
    fun_name <- map_chr(split_names, splitter)
    outer <- map_int(split_names, length) == 2

    argument_type <-
        argument_type %>%
        mutate(pack_name = pack_name, fun_name = fun_name, outer = outer) %>%
        filter(pack_name != "<NA>" & outer) %>%
        select(-qual_name, -outer)

    list(argument_type = argument_type)
}

################################################################################
## INDIRECT EFFECTS
################################################################################

reduce_indirect_effects <- function(data) {

    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, anonymous)
    effects <- data$output$effects

    arguments <-
        arguments %>%
        filter(vararg == 0 & missing == 0) %>%
        select(arg_id, arg_type, expr_type, val_type)

    str(effects)

    indirect_effects <-
        effects %>%
        filter(transitive) %>%
        left_join(functions, by = c("source_fun_id" = "fun_id"))%>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(arguments, by = c("source_arg_id" = "arg_id")) %>%
        select(-source_arg_id, -source_fun_id, -source_call_id, -anonymous) %>%
        rename(source_qual_name = qual_name,
               source_arg_type = arg_type,
               source_expr_type = expr_type,
               source_val_type = val_type) %>%
        left_join(functions, by = "fun_id") %>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(arguments, by = "arg_id") %>%
        select(-fun_id, -call_id, -anonymous) %>%
        count(type, transitive, source_formal_pos, formal_pos,
              source_qual_name, qual_name,
              source_arg_type, source_expr_type,
              arg_type, expr_type, source_val_type, val_type, name = "operation_count")

    str(indirect_effects)

    list(indirect_effects = indirect_effects)
}

summarize_indirect_effects <- function(output) {
    indirect_effects <- output$indirect_effects

    print(str(indirect_effects))

    splitter <- function(split) {
        split <- split[-1]
        paste("`", split, "`", sep="", collapse = " ")
    }

    indirect_effects <-
        indirect_effects %>%
        count(type, transitive, source_formal_pos, formal_pos,
              source_qual_name, qual_name,
              source_arg_type, source_expr_type,
              arg_type, expr_type, source_val_type, val_type, wt = operation_count, name = "operation_count")

    split_names <- str_split(indirect_effects$qual_name, fixed(NAME_SEPARATOR))
    pack_name <- map_chr(split_names, ~.[1])
    fun_name <- map_chr(split_names, splitter)
    outer <- map_int(split_names, length) == 2

    indirect_effects <-
        indirect_effects %>%
        mutate(pack_name = pack_name,
               fun_name = fun_name,
               outer = outer) %>%
        filter(pack_name != "<NA>" & outer) %>%
        select(-qual_name, -outer)

    source_split_names <- str_split(indirect_effects$source_qual_name, fixed(NAME_SEPARATOR))
    source_pack_name <- map_chr(source_split_names, ~.[1])
    source_fun_name <- map_chr(source_split_names, splitter)
    source_outer <- map_int(source_split_names, length) == 2

    indirect_effects <-
        indirect_effects %>%
        mutate(source_pack_name = source_pack_name,
               source_fun_name = source_fun_name,
               source_outer = source_outer) %>%
        filter(source_pack_name != "<NA>" & source_outer) %>%
        select(-source_qual_name, -source_outer)

    list(indirect_effects = indirect_effects)
}

################################################################################
## METAPROGRAMMING
################################################################################

reduce_metaprogramming <- function(data) {

    arguments <- data$output$arguments
    functions <- select(data$output$functions, fun_id, qual_name, anonymous)
    metaprograming <- data$output$metaprogramming

    arguments <-
        arguments %>%
        filter(vararg == 0 & missing == 0) %>%
        select(arg_id, arg_type, expr_type, val_type)

    str(metaprogramming)

    metaprogramming <-
        metaprogramming %>%
        left_join(functions, by = c("source_fun_id" = "fun_id"))%>%
        filter(is.na(anonymous) | !anonymous) %>%
        left_join(arguments, by = c("source_arg_id" = "arg_id")) %>%
        select(-source_arg_id, -source_fun_id, -source_call_id, -anonymous) %>%
        rename(source_qual_name = qual_name,
               source_arg_type = arg_type,
               source_expr_type = expr_type,
               source_val_type = val_type) %>%
        left_join(functions, by = "sink_fun_id") %>%
        filter(is.na(anonymous) | !anonymous) %>%
        select(-sink_fun_id, -sink_call_id, -anonymous) %>%
        count(meta_type, source_qual_name, source_arg_type, source_expr_type, source_val_type,
              source_formal_pos, qual_name, depth, name = "argument_count")

    str(metaprogramming)

    list(metaprogramming = metaprogramming)
}


main()

warnings()
