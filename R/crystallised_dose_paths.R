
#' Dose-paths with probabilities attached.
#'
#' \code{\link{dose_paths}} reflect all possible paths a dose-finding trial may
#' take. When the probability of those paths is calculated using an assumed set
#' of true dose-event probabilities, in this package those paths are said to be
#' crysallised. Once crystallised, operating charactersitics can be calculated.
#'
#' @param dose_paths Object of type \code{\link{dose_paths}}
#' @param true_prob_tox vector of toxicity probabilities at doses 1..n
#' @param true_prob_eff vector of efficacy probabilities at doses 1..n,
#' optionally NULL if efficacy not evaluated.
#' @param terminal_nodes tibble of terminal nodes on the dose-paths
#'
#' @return An object of type crystallised_dose_paths
#' @export
#'
#' @examples
#' # Calculate dose paths for the first three cohorts in a 3+3 trial of 5 doses:
#' paths <- get_three_plus_three(num_doses = 5) %>%
#'   get_dose_paths(cohort_sizes = c(3, 3, 3))
#'
#' # Set the true probabilities of toxicity
#' true_prob_tox <- c(0.12, 0.27, 0.44, 0.53, 0.57)
#' # Crytallise the paths with the probabilities of toxicity
#' x <- paths %>% calculate_probabilities(true_prob_tox)
#' # And then examine, for example, the probabilities of recommending each dose
#' # at the terminal nodes of these paths:
#' prob_recommend(x)
crystallised_dose_paths <- function(dose_paths, true_prob_tox,
                                    true_prob_eff = NULL, terminal_nodes) {
  l <- list(dose_paths = dose_paths,
            true_prob_tox = true_prob_tox,
            supports_efficacy = !is.null(true_prob_eff),
            true_prob_eff = true_prob_eff,
            terminal_nodes = terminal_nodes)
  class(l) <- 'crystallised_dose_paths'
  l
}

#' @importFrom dplyr mutate summarise
#' @importFrom purrr map_int
#' @importFrom magrittr %>%
#' @export
num_patients.crystallised_dose_paths <- function(x, ...) {

  var <- prob_outcomes <- scaled_var <- . <- NULL

  x$terminal_nodes %>%
    mutate(
      var = map_int(fit, num_patients),
      scaled_var = prob_outcomes * var
      ) %>%
    summarise(sum(scaled_var)) %>%
    .[[1]]
}

#' @export
num_doses.crystallised_dose_paths <- function(x, ...) {
  if(length(x$dose_paths) > 0)
    return(num_doses(x$dose_paths[[1]]$fit))
  else
    return(0)
}

#' @export
dose_indices.crystallised_dose_paths <- function(x, ...) {
  if(length(x$dose_paths) > 0)
    dose_indices(x$dose_paths[[1]]$fit)
  else
    integer(length = 0)
}

#' @importFrom dplyr mutate summarise
#' @importFrom purrr map_int
#' @importFrom magrittr %>%
#' @export
continue.crystallised_dose_paths <- function(x, ...) {

  var <- prob_outcomes <- scaled_var <- . <- NULL

  x$terminal_nodes %>%
    mutate(
      var = map_int(fit, continue),
      scaled_var = prob_outcomes * var
    ) %>%
    summarise(sum(scaled_var)) %>%
    .[[1]]
}

#' @importFrom dplyr mutate group_by summarise
#' @importFrom purrr map
#' @importFrom magrittr %>%
#' @export
n_at_dose.crystallised_dose_paths <- function(x, dose = NULL, ...) {

  if(is.null(dose)) {
    d <- var <- prob_outcomes <- scaled_var <- . <- NULL

    var_vec <- x$terminal_nodes %>%
      mutate(
        d = map(fit, dose_indices),
        var = map(fit, n_at_dose)
      ) %>%
      unnest(c(prob_outcomes, d, var)) %>%
      mutate(scaled_var = prob_outcomes * var) %>%
      group_by(d) %>%
      summarise(sum(scaled_var)) %>% .[[2]]

    names(var_vec) <- dose_indices(x)
    var_vec
  } else {

    var <- scaled_var <- . <- NULL

    var_vec <- x$terminal_nodes %>%
      mutate(
        var = map(fit, n_at_dose, dose = dose)
      ) %>%
      unnest(c(prob_outcomes, var)) %>%
      mutate(scaled_var = prob_outcomes * var) %>%
      summarise(sum(scaled_var, na.rm = TRUE)) %>% .[[1]]

    var_vec
  }
}

#' @export
n_at_recommended_dose.crystallised_dose_paths <- function(x, ...) {
  return(n_at_dose(x, dose = 'recommended'))
}

#' @importFrom dplyr mutate group_by summarise
#' @importFrom purrr map
#' @importFrom magrittr %>%
#' @export
tox_at_dose.crystallised_dose_paths <- function(x, ...) {

  # if(is.null(dose)) {
  d <- var <- prob_outcomes <- scaled_var <- . <- NULL

  var_vec <- x$terminal_nodes %>%
    mutate(
      d = map(fit, dose_indices),
      var = map(fit, tox_at_dose)
    ) %>%
    unnest(c(prob_outcomes, d, var)) %>%
    mutate(scaled_var = prob_outcomes * var) %>%
    group_by(d) %>%
    summarise(sum(scaled_var)) %>% .[[2]]

  names(var_vec) <- dose_indices(x)
  var_vec
}

#' @export
num_tox.crystallised_dose_paths <- function(x, ...) {
  sum(tox_at_dose(x, ...))
}

#' @importFrom dplyr mutate group_by summarise
#' @importFrom purrr map
#' @importFrom magrittr %>%
#' @export
eff_at_dose.crystallised_dose_paths <- function(x, ...) {

  supports_efficacy <- ifelse(
    'supports_efficacy' %in% names(x),
    x$supports_efficacy,
    FALSE
  )
  if(supports_efficacy) {
    d <- var <- prob_outcomes <- scaled_var <- . <- NULL

    var_vec <- x$terminal_nodes %>%
      mutate(
        d = map(fit, dose_indices),
        var = map(fit, eff_at_dose)
      ) %>%
      unnest(c(prob_outcomes, d, var)) %>%
      mutate(scaled_var = prob_outcomes * var) %>%
      group_by(d) %>%
      summarise(sum(scaled_var)) %>% .[[2]]

    names(var_vec) <- dose_indices(x)
    var_vec
  } else {
    return(rep(NA, num_doses(x)))
  }
}

#' @export
num_eff.crystallised_dose_paths <- function(x, ...) {
  sum(eff_at_dose(x, ...))
}

#' @importFrom dplyr mutate filter summarise
#' @importFrom purrr map_int
#' @export
prob_recommend.crystallised_dose_paths <- function(x, ...) {

  prob_outcomes <- . <- NULL

  df <- x$terminal_nodes %>%
    mutate(recommended_dose = map_int(fit, recommended_dose))
  prob_stop <- df %>% filter(is.na(recommended_dose)) %>%
    summarise(prob = sum(prob_outcomes)) %>% .[[1]]

  .get_prob_d <- function(i) {
    . <- prob_outcomes <- recommended_dose <- NULL
    df %>%
      filter(recommended_dose == i) %>%
      summarise(prob = sum(prob_outcomes)) %>% .[[1]]
  }

  prob_d <- sapply(dose_indices(x$dose_paths), .get_prob_d)
  prob_rec <- c(prob_stop, prob_d)
  names(prob_rec) <- c('NoDose', dose_indices(x$dose_paths))
  prob_rec
}

#' @importFrom dplyr mutate group_by summarise
#' @importFrom tidyr unnest
#' @importFrom purrr map
#' @export
prob_administer.crystallised_dose_paths <- function(x, ...) {

  prob_outcomes <- dose <- prob_admin_d <- scaled_prob_administer <- NULL
  . <- NULL

  df <- x$terminal_nodes %>%
    mutate(
      dose = map(fit, dose_indices),
      prob_admin_d = map(fit, prob_administer)
    )

  grouped_df <- df %>%
    unnest(c(prob_outcomes, dose, prob_admin_d)) %>%
    mutate(scaled_prob_administer = prob_outcomes * prob_admin_d) %>%
    group_by(dose) %>%
    summarise(prob_admin_d = sum(scaled_prob_administer))

  prob_admin <- grouped_df %>% .[[2]]
  names(prob_admin) <- grouped_df %>% .[[1]]
  prob_admin
}

#' @export
print.crystallised_dose_paths <- function(x, ...) {

  supports_efficacy <- ifelse(
    'supports_efficacy' %in% names(x),
    x$supports_efficacy,
    FALSE
  )

  cat('Number of nodes:',  length(x$dose_paths), '\n')
  cat('Number of terminal nodes:', nrow(x$terminal_nodes), '\n')
  cat('\n')

  cat('Number of doses:', num_doses(x), '\n')
  cat('\n')

  ptox <- x$true_prob_tox
  names(ptox) <- dose_indices(x)
  cat('True probability of toxicity:\n')
  print(ptox, digits = 3)
  cat('\n')

  if(supports_efficacy) {
    peff <- x$true_prob_eff
    names(peff) <- dose_indices(x)
    cat('True probability of efficacy:\n')
    print(peff, digits = 3)
    cat('\n')
  }

  cat('Probability of recommendation:\n')
  print(
    noquote(
      format(prob_recommend(x), digits = 3, nsmall = 3, scientific = FALSE)
    ),
    digits = 3
  )
  cat('\n')

  cat('Probability of continuance:\n')
  print(continue(x), digits = 3)
  cat('\n')

  cat('Probability of administration:\n')
  print(
    noquote(
      format(prob_administer(x), digits = 3, nsmall = 3, scientific = FALSE)
    ),
    digits = 3
  )
  cat('\n')

  cat('Expected sample size:\n')
  cat(num_patients(x))
  cat('\n')
  cat('\n')

  cat('Expected total toxicities:\n')
  cat(num_tox(x))
  cat('\n')
  cat('\n')

  if(supports_efficacy) {
    cat('Expected total efficacies:\n')
    cat(num_eff(x))
    cat('\n')
    cat('\n')
  }
}

#' @export
summary.crystallised_dose_paths <- function(object, ...) {

  supports_efficacy <- ifelse(
    'supports_efficacy' %in% names(object),
    object$supports_efficacy,
    FALSE
  )

  dose_labs <- c('NoDose', as.character(dose_indices(object)))

  if(supports_efficacy) {
    tibble(
      dose = ordered(dose_labs, levels = dose_labs),
      tox = c(0, tox_at_dose(object)),
      n = c(0, n_at_dose(object)),
      true_prob_tox = c(0, object$true_prob_tox),
      true_prob_eff = c(0, object$true_prob_eff),
      prob_recommend = unname(prob_recommend(object)),
      prob_administer = c(0, prob_administer(object))
    )
  } else {
    tibble(
      dose = ordered(dose_labs, levels = dose_labs),
      tox = c(0, tox_at_dose(object)),
      n = c(0, n_at_dose(object)),
      true_prob_tox = c(0, object$true_prob_tox),
      prob_recommend = unname(prob_recommend(object)),
      prob_administer = c(0, prob_administer(object))
    )
  }
}
