
test_that('demand_n_at_dose_selector does what it should.', {

  skeleton <- c(0.05, 0.1, 0.25, 0.4, 0.6)
  target <- 0.25

  # To see this class work, we have to see it used in conjucntion with a class
  # that would like to stop. We sue stop_at_n for simplicity.

  # Example 1 - demand n at any dose
  model1 <- get_dfcrm(skeleton = skeleton, target = target) %>%
    stop_at_n(n = 12) %>%
    demand_n_at_dose(n = 12, dose = 'any')

  # Don't stop when there are at most 9 at a dose:
  fit1 <- model1 %>% fit('1NNN 2NTN 2TNN 2NNN')
  expect_equal(recommended_dose(fit1), fit1$parent$parent$dfcrm_fit$mtd)
  expect_true(continue(fit1))

  # But do stop when there are 12 at any particular dose:
  fit2 <- model1 %>% fit('1NNN 2NTN 2TNN 2NNN 2NTT')
  expect_equal(recommended_dose(fit2), fit2$parent$parent$dfcrm_fit$mtd)
  expect_false(continue(fit2))



  # Example 2 - demand n at any dose
  model2 <- get_dfcrm(skeleton = skeleton, target = target) %>%
    stop_at_n(n = 12) %>%
    demand_n_at_dose(n = 9, dose = 'recommended')

  # Don't stop when there are 12 in total:
  fit3 <- model2 %>% fit('1TNN 1NNN 2NTN 2TNN')
  expect_equal(recommended_dose(fit3), fit3$parent$parent$dfcrm_fit$mtd)
  expect_true(continue(fit3))

  # But do stop when there are 9 at dose 2:
  fit4 <- model2 %>% fit('1TNN 1NNN 2NTN 2TNN 2NNN')
  expect_equal(recommended_dose(fit4), fit4$parent$parent$dfcrm_fit$mtd)
  expect_false(continue(fit4))
  # Implicitly, this suggests the recommended dose is 2:
  expect_equal(recommended_dose(fit4), 2)



  # Example 3 - demand n at a particular dose
  model3 <- get_dfcrm(skeleton = skeleton, target = target) %>%
    stop_at_n(n = 12) %>%
    demand_n_at_dose(n = 9, dose = 2)

  # Don't stop when there are 12 in total:
  fit5 <- model3 %>% fit('1TNN 1NNN 2NTN 2TNN')
  expect_equal(recommended_dose(fit5), fit5$parent$parent$dfcrm_fit$mtd)
  expect_true(continue(fit5))

  # But do stop when there are 9 at dose 2:
  fit6 <- model3 %>% fit('1TNN 1NNN 2NTN 2TNN 2NNN')
  expect_equal(recommended_dose(fit6), fit6$parent$parent$dfcrm_fit$mtd)
  expect_false(continue(fit6))

})


test_that('demand_n_at_dose_selector supports correct interface.', {

  skeleton <- c(0.05, 0.1, 0.25, 0.4, 0.6)
  target <- 0.25

  model_fitter <- get_dfcrm(skeleton = skeleton, target = target) %>%
    demand_n_at_dose(dose = 'recommended', n = 9)


  # Example 1, using outcome string
  x <- fit(model_fitter, '1NNN 2NNN')

  expect_equal(num_patients(x), 6)
  expect_true(is.integer(num_patients(x)))

  expect_equal(cohort(x), c(1,1,1, 2,2,2))
  expect_true(is.integer(cohort(x)))

  expect_equal(doses_given(x), c(1,1,1, 2,2,2))
  expect_true(is.integer(doses_given(x)))

  expect_equal(tox(x), c(0,0,0, 0,0,0))
  expect_true(is.integer(tox(x)))

  expect_true(all(model_frame(x) - data.frame(patient = c(1,2,3,4,5,6),
                                              cohort = c(1,1,1,2,2,2),
                                              dose = c(1,1,1,2,2,2),
                                              tox = c(0,0,0,0,0,0)) == 0))

  expect_equal(num_doses(x), 5)
  expect_true(is.integer(num_doses(x)))

  expect_equal(recommended_dose(x), 5)
  expect_true(is.integer(recommended_dose(x)))

  expect_equal(continue(x), TRUE)
  expect_true(is.logical(continue(x)))

  expect_equal(n_at_dose(x), c(3,3,0,0,0))
  expect_true(is.integer(n_at_dose(x)))

  expect_equal(tox_at_dose(x), c(0,0,0,0,0))
  expect_true(is.integer(tox_at_dose(x)))

  expect_true(is.numeric(empiric_tox_rate(x)))

  expect_true(is.numeric(mean_prob_tox(x)))

  expect_true(is.numeric(median_prob_tox(x)))

  expect_true(is.numeric(prob_tox_exceeds(x, 0.5)))



  # Example 2, using trivial outcome string
  x <- fit(model_fitter, '')

  expect_equal(num_patients(x), 0)
  expect_true(is.integer(num_patients(x)))

  expect_equal(cohort(x), integer(0))
  expect_true(is.integer(cohort(x)))

  expect_equal(doses_given(x), integer(0))
  expect_true(is.integer(doses_given(x)))

  expect_equal(tox(x), integer(0))
  expect_true(is.integer(tox(x)))

  mf <- model_frame(x)
  expect_equal(nrow(mf), 0)
  expect_equal(ncol(mf), 4)

  expect_equal(num_doses(x), 5)
  expect_true(is.integer(num_doses(x)))

  expect_equal(recommended_dose(x), 1)
  expect_true(is.integer(recommended_dose(x)))

  expect_equal(continue(x), TRUE)
  expect_true(is.logical(continue(x)))

  expect_equal(n_at_dose(x), c(0,0,0,0,0))
  expect_true(is.integer(n_at_dose(x)))

  expect_equal(tox_at_dose(x), c(0,0,0,0,0))
  expect_true(is.integer(tox_at_dose(x)))

  expect_true(is.numeric(empiric_tox_rate(x)))

  expect_true(is.numeric(mean_prob_tox(x)))

  expect_true(is.numeric(median_prob_tox(x)))

  expect_true(is.numeric(prob_tox_exceeds(x, 0.5)))



  # Example 3, using tibble of outcomes
  outcomes <- tibble(
    cohort = c(1,1,1, 2,2,2),
    dose = c(1,1,1, 2,2,2),
    tox = c(0,0,0, 0,0,1)
  )
  x <- fit(model_fitter, outcomes)

  expect_equal(num_patients(x), 6)
  expect_true(is.integer(num_patients(x)))

  expect_equal(cohort(x), c(1,1,1, 2,2,2))
  expect_true(is.integer(cohort(x)))

  expect_equal(doses_given(x), c(1,1,1, 2,2,2))
  expect_true(is.integer(doses_given(x)))

  expect_equal(tox(x), c(0,0,0, 0,0,1))
  expect_true(is.integer(tox(x)))

  expect_true(all((model_frame(x) - data.frame(patient = c(1,2,3,4,5,6),
                                               cohort = c(1,1,1,2,2,2),
                                               dose = c(1,1,1,2,2,2),
                                               tox = c(0,0,0,0,0,1))) == 0))

  expect_equal(num_doses(x), 5)
  expect_true(is.integer(num_doses(x)))

  expect_equal(recommended_dose(x), 2)
  expect_true(is.integer(recommended_dose(x)))

  expect_equal(continue(x), TRUE)
  expect_true(is.logical(continue(x)))

  expect_equal(n_at_dose(x), c(3,3,0,0,0))
  expect_true(is.integer(n_at_dose(x)))

  expect_equal(tox_at_dose(x), c(0,1,0,0,0))
  expect_true(is.integer(tox_at_dose(x)))

  expect_true(is.numeric(empiric_tox_rate(x)))

  expect_true(is.numeric(mean_prob_tox(x)))

  expect_true(is.numeric(median_prob_tox(x)))

  expect_true(is.numeric(prob_tox_exceeds(x, 0.5)))

})