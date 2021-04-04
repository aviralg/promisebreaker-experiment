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
    else if (step == "reduce") {
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
        filename <- path_file(filepath)
        package <- path_file(path_dir(filepath))
        type <- path_file(path_dir(path_dir(filepath)))

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
## SIGNATURES
################################################################################

reduce_signature <- function(data) {
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

summarize_signature <- function(data) {
    arguments <-
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

    list(arguments = arguments)
}

################################################################################
## FUNCTIONS
################################################################################

reduce_functions <- function(data) {
    arguments <- data$output$arguments
    functions <- data$output$functions

    function_summary <-
        functions %>%
        count(anonymous, qual_name, name = "count") %>%
        add_cum_perc()

    function_summary %>%
        filter(anonymous) %>%
        print()

    function_summary %>%
        filter(!anonymous) %>%
        print()
}

combine_functions <- function(data) {
}


################################################################################
## SIGNATURE
################################################################################


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
    functions <- select(data$output$functions, fun_id, qual_name, fun_hash, fun_def, anonymous)
    arg_ref <- data$output$arg_ref
    calls <- data$output$calls

    arg_ref_summary <-
        arguments %>%
        filter(vararg == 0, ref_seq != "") %>%
        count(fun_id, formal_pos, ref_seq, self_ref_seq, name = "count") %>%
        left_join(functions, by = "fun_id") %>%
        filter(!anonymous) %>%
        count(qual_name, formal_pos, ref_seq, self_ref_seq,
              wt = count, name = "arg_count") %>%
        mutate(ref_seq = str_trunc(ref_seq, 20),
               self_ref_seq = str_trunc(self_ref_seq, 20)) %>%
        print()


        arg_ref %>%
            left_join(functions, by = "fun_id") %>%
            print()

    ##effects %>%
    ##    count(transitive, type, name = "count") %>%
    ##    arrange(transitive, desc(count)) %>%
    ##    print()
    ##
    ##effects %>%
    ##    filter(!transitive) %>%
    ##    distinct(type, arg_id) %>%
    ##    count(type, name = "count") %>%
    ##    arrange(desc(count)) %>%
    ##    print()
    ##
    ##effects %>%
    ##    filter(transitive) %>%
    ##    distinct(type, arg_id) %>%
    ##    count(type, name = "count") %>%
    ##    arrange(desc(count)) %>%
    ##    print()

}

summarize_reflection <- function(data) {
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

summarize_effects <- function(data) {
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

main()
