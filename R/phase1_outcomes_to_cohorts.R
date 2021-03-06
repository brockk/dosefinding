
#' @title Break a phase I outcome string into a list of cohort parts.
#'
#' @description Break a phase I outcome string into a list of cohort parts.
#'
#' @param outcomes character string representing the doses given, outcomes
#' observed, and timing of analyses. See Description.
#'
#' @description Break a phase I outcome string into a list of cohort parts.
#'
#' The outcome string describes the doses given, outcomes observed and the
#' timing of analyses that recommend a dose. The format of the string is
#' described in Brock (2019), and that itself is the phase I analogue of the
#' similar idea described in Brock _et al_. (2017).
#'
#' The letters T and N are used to represents patients that experienced
#' (T)oxicity and (N)o toxicity. These letters are concatenated after numerical
#' dose-levels to convey the outcomes of cohorts of patients.
#' For instance, \code{2NNT} represents a cohort of three patients that were
#' treated at dose-level 2, one of whom experienced toxicity, and two that did
#' not. The results of cohorts are separated by spaces and it is assumed that a
#' dose-finding decision takes place at the end of a cohort. Thus,
#' \code{2NNT 1NN} builds on our previous example, where the next cohort of two
#' were treated at dose-level 1 and neither of these patients experienced
#' toxicity. See examples.
#'
#' @return a list with a slot for each cohort. Each cohort slot is itself a
#' list, containing elements:
#' * \code{dose}, the integer dose delivered to the cohort;
#' * \code{outcomes}, a character string representing the \code{T} or \code{N}
#'  outcomes for the patients in this cohort.
#'
#' @export
#'
#' @examples
#' x = phase1_outcomes_to_cohorts('1NNN 2NNT 3TT')
#' length(x)
#' x[[1]]$dose
#' x[[1]]$outcomes
#' x[[2]]$dose
#' x[[2]]$outcomes
#' x[[3]]$dose
#' x[[3]]$outcomes
#'
#' @references
#' Brock, K. (2019). trialr: Bayesian Clinical Trial Designs in R and Stan.
#' arXiv:1907.00161 [stat.CO]
#'
#' Brock, K., Billingham, L., Copland, M., Siddique, S., Sirovica, M., & Yap, C.
#' (2017). Implementing the EffTox dose-finding design in the Matchpoint trial.
#' BMC Medical Research Methodology, 17(1), 112.
#' https://doi.org/10.1186/s12874-017-0381-x
#'
#' @importFrom stringr str_extract str_detect str_extract_all
phase1_outcomes_to_cohorts <- function(outcomes) {

  if(is.character(outcomes)) {
    if(outcomes == '') return(list())
  }

  # Matching is done by regex.
  # This pattern ensures that outcomes is valid. It is the gate-keeper.
  # It allows leading and trailing white space and demands >0 cohort strings.
  # e.g. "2NNT 3TT 2N "
  valid_str_match <- '^\\s*(\\d+[NT]+\\s*)+$'
  # This pattern identifies the individual cohort strings, e.g. "2NNT"
  cohort_str_match <- '\\d+[NT]+'
  # This pattern extracts the dose-level from a cohort string, e.g. "2"
  dl_str_match <- '\\d+'
  # And this pattern extracts the outcomes from a cohort string, e.g "NNT"
  outcomes_match_str <- '[NT]+'

  cohorts <- list()
  cohort_id <- 1

  if(str_detect(outcomes, valid_str_match)) {
    cohort_strs <- str_extract_all(
      outcomes, cohort_str_match)[[1]]
    for(cohort_str in cohort_strs) {
      c_dl <- as.integer(str_extract(cohort_str, dl_str_match))
      if(c_dl <= 0) stop('Dose-levels must be strictly positive integers.')
      c_outcomes <- str_extract(cohort_str, outcomes_match_str)
      cohorts[[cohort_id]] <- list(dose = c_dl, outcomes = c_outcomes)
      cohort_id <- cohort_id + 1
    }
  } else {
    stop(paste0('"', outcomes, '" is not a valid outcome string.
                A valid example is "1N 2NN 3TT 2NT"'))
  }

  cohorts
}
