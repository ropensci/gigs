# GROWTH COMPUTATION -----------------------------------------------------------
#   Takes multiple input vectors, passes these to z-scoring/centile-ing
#   functions, then returns a single vector.

#' Get size-for-gestational age categories using multiple vectors and the
#' INTERGROWTH-21<sup>st</sup> weight-for-gestational age standard
#'
#' @inheritParams shared_roxygen_params
#' @param weight_kg Numeric vector of length one or more with weight value(s) in
#'   kg. It is assumed that weight measurements provided to this function are
#'   birth weights recorded <12 hours after an infant's birth.
#' @param gest_days Numeric vector of length one or more with gestational ages
#'   in days. Classifications can only be computed when `gest_days` is between
#'   `168` and `300`, as these are the limits of the INTERGROWTH-21<sup>st</sup>
#'   Newborn Size standards (including the Very Preterm standards). By default,
#'   gigs will warn you about elements of `gest_days` which are either outside
#'   these bounds, are `NA`, or are `Inf`. You can customise this behaviour
#'   using the [GIGS package-level options][gigs_options].
#' @param severe A single logical value specifying whether to categorise SGA
#'   values below the third centile (`0.03`) as `"SGA(<3)"`. Default = `FALSE`.
#' @returns An object of class factor with the same length as the longest input
#'   vector, containing size-for-GA classifications. If `severe = FALSE`, levels
#'   are `c("SGA", "AGA", "LGA")`. If `severe = TRUE`, levels are `c("SGA(<3)",
#'   "SGA", "AGA", "LGA")`. By default, gigs will inform you this object 
#'   contains unused factor levels. You can change this behaviour using the 
#'   [GIGS package-level option][gigs_options] 
#'   `.gigs_options$handle_unused_levels`.
#' @examples
#' # By default, does not differentiate between p < 0.03 and p < 0.10
#' compute_sfga(
#'   weight_kg = c(2.2, 2.5, 3.3, 4.0),
#'   gest_days = 266:269,
#'   sex = c("F", "M", "F", "M")
#' )
#'
#' # With severe = TRUE, highlights p < 0.03
#' compute_sfga(
#'   weight_kg = c(2.2, 2.5, 3.3, 4.0),
#'   gest_days = 266:269,
#'   sex = c("F", "M", "F", "M"),
#'   severe = TRUE
#' )
#' @inherit categorise_sfga details note
#' @note Input vectors are recycled by [vctrs::vec_recycle_common()], and must
#'   adhere to the
#'   \link[vctrs:theory-faq-recycling]{vctrs recycling rules}.
#' @inherit categorise_sfga references
#' @export
compute_sfga <- function(weight_kg,
                         gest_days,
                         sex,
                         severe = FALSE) {
  checkmate::qassert(severe, rules = "B1")
  inputs <- validate_inputs(y = weight_kg, x = gest_days, sex = sex,
                            yzp_name = "weight_kg", x_name = "gest_days",
                            family = "ig_nbs", acronym = "wfga")
  p <- do.call(what = ig_nbs_v2c_internal,
               args = inputs[!names(inputs) == "family"])
  categorise_sfga_internal(p, severe = severe)
}

#' Get small vulnerable newborn categories using multiple vectors and the
#' INTERGROWTH-21<sup>st</sup> weight-for-gestational age standard
#'
#' @inherit compute_sfga params note
#' @returns An object of class factor with the same length as the longest input
#'   vector, containing small vulnerable newborn classifications. Its levels
#'   are `c("Preterm SGA", "Preterm AGA", "Preterm LGA", "Term SGA", "Term AGA",
#'   "Term LGA")`. By default, gigs will inform you this object contains unused 
#'   factor levels. You can change this behaviour using the 
#'   [GIGS package-level option][gigs_options] 
#'   `.gigs_options$handle_unused_levels`.
#' @inherit categorise_svn details note references
#' @examples
#' compute_svn(
#'   weight_kg = c(1.5, 2.6, 2.6, 3.5),
#'   gest_days = c(235, 257, 275, 295),
#'   sex = c("F", "M", "F", "M")
#' )
#' @export
compute_svn <- function(weight_kg, gest_days, sex) {
  inputs <- validate_inputs(y = weight_kg, x = gest_days, sex = sex,
                            yzp_name = "weight_kg", x_name = "gest_days",
                            family = "ig_nbs", acronym = "wfga")
  p <- do.call(what = ig_nbs_v2c_internal,
               args = inputs[!names(inputs) == "family"])
  categorise_svn_internal(p, gest_days = gest_days)
}

#' Get stunting categories using multiple vectors and GIGS-recommended growth
#' standards
#'
#' @inheritParams compute_wasting
#' @inherit categorise_stunting params details note references return
#' @inherit gigs_waz params
#' @examples
#' # The first observation for each infant in `id` uses the INTERGROWTH-21st
#' #  Newborn Size standards; the next two use either the INTERGROWTH-21st
#' # Postnatal Growth standards or WHO Child Growth Standards.
#' compute_stunting(
#'   lenht_cm = c(52.2, 60.4, 75, 52.2, 60.4, 75),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F"),
#'   id = factor(c("A", "A", "A", "B", "B", "B"))
#' )
#'
#' # With outlier flagging:
#' compute_stunting(
#'   lenht_cm = c(52.2, 75.4, 63.1),
#'   age_days = c(357, 375, 250),
#'   gest_days = c(196, 287, 266),
#'   sex = c("M", "M", "F"),
#'   id = factor(c("A", "B", "C")),
#'   outliers = TRUE
#' )
#'
#' # If you don't specify `id`, the function will not identify that the fourth
#' # data point is a birth measurement, and will categorise it as severe
#' # stunting instead of not stunting
#' compute_stunting(
#'   lenht_cm = c(40.0, 60.4, 75, 40.0, 60.4, 75),
#'   age_days = c(0.45, 100, 500, 0.5, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F")
#' )
#' @export
compute_stunting <- function(lenht_cm,
                             age_days,
                             gest_days,
                             sex,
                             id = NULL,
                             outliers = FALSE) {
  checkmate::qassert(outliers, rules = "B1")
  validated <- validate_lhaz_params(lenht_cm = lenht_cm,
                                    age_days = age_days,
                                    gest_days = gest_days,
                                    sex = sex,
                                    id = id)
  lhaz <- do.call(validated, what = gigs_lhaz_internal)
  categorise_stunting_internal(lhaz, outliers = outliers)
}

#' Get wasting categories using multiple vectors and GIGS-recommended growth
#' standards
#'
#' @param weight_kg Numeric vector of length one or more with weight
#'   measurement(s) in kg.
#' @param lenht_cm Numeric vector of length one or more with length/height
#'   measurement(s) in cm.
#' @param age_days Numeric vector of length one or more with age(s) in days
#'   for each child. Should be between `0` to `1856` days. By default, gigs will
#'   replace out-of-bounds elements in `age_days` with `NA` and warn you. This
#'   behaviour can be customised using the functions in [gigs_options].
#' @param gest_days Numeric vector with gestational age(s) at birth in days.
#' @inheritParams compute_sfga
#' @inheritParams categorise_stunting
#' @inherit gigs_waz params
#' @examples
#' # The first observation for each infant in `id` uses the INTERGROWTH-21st
#' #  Newborn Size standards; the next two use either the INTERGROWTH-21st
#' # Postnatal Growth standards or WHO Child Growth Standards.
#' compute_wasting(
#'   weight_kg = c(3, 6, 11, 3, 6, 11),
#'   lenht_cm = c(52.2, 60.4, 61, 52.2, 60.4, 61),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F"),
#'   id = factor(c("A", "A", "A", "B", "B", "B"))
#' )
#'
#' # With outlier flagging:
#' compute_wasting(
#'   weight_kg = c(3, 6, 11, 3, 6, 11),
#'   lenht_cm = c(52.2, 60.4, 61, 52.2, 60.4, 61),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F"),
#'   id = factor(c("A", "A", "A", "B", "B", "B")),
#'   outliers = TRUE
#' )
#'
#' # If you don't specify `id`, the function will not identify that the fourth
#' # data point is a birth measurement. This means a weight-for-length z-score
#' # (and resulting wasting classification) will be calculated for the fourth
#' # data point, which is wrong here
#' compute_wasting(
#'   weight_kg = c(3, 6, 11, 3, 6, 11),
#'   lenht_cm = c(52.2, 60.4, 61, 52.2, 60.4, 61),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F")
#' )
#' @inherit categorise_wasting details note references return
#' @export
compute_wasting <- function(weight_kg,
                            lenht_cm,
                            age_days,
                            gest_days,
                            sex,
                            id = NULL,
                            outliers = FALSE) {
  checkmate::qassert(outliers, rules = "B1")
  validated <- validate_wlz_params(weight_kg = weight_kg,
                                   lenht_cm = lenht_cm,
                                   age_days = age_days,
                                   gest_days = gest_days,
                                   sex = sex,
                                   id = id)
  wlz <- do.call(validated, what = gigs_wlz_internal)
  categorise_wasting_internal(wlz, outliers = outliers)
}

#' Get weight-for-age categories using multiple vectors and GIGS-recommended
#' growth standards
#'
#' @inheritParams compute_wasting
#' @inherit categorise_wasting params note references return
#' @inherit gigs_waz params
#' @examples
#' # The first observation for each infant in `id` uses the INTERGROWTH-21st
#' #  Newborn Size standards; the next two use either the INTERGROWTH-21st
#' # Postnatal Growth standards or WHO Child Growth Standards.
#' compute_wfa(
#'   weight_kg = c(2.05, 8, 18, 2.05, 8, 18),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F"),
#'   id = factor(c("A", "A", "A", "B", "B", "B"))
#' )
#'
#' # With outlier flagging:
#' compute_wfa(
#'   weight_kg = c(2.05, 8, 18, 2.05, 8, 18),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F"),
#'   id = factor(c("A", "A", "A", "B", "B", "B")),
#'   outliers = TRUE
#' )
#'
#' # If you don't specify `id`, the function will not identify that the fourth
#' # data point is a birth measurement, and will categorise it as underweight
#' # instead of severely stunting
#' compute_wfa(
#'   weight_kg = c(2.05, 8, 18, 2.05, 8, 18),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F")
#' )
#' @inherit categorise_wfa details note references return
#' @export
compute_wfa <- function(weight_kg,
                        age_days,
                        gest_days,
                        sex,
                        id = NULL,
                        outliers = FALSE) {
  checkmate::qassert(outliers, rules = "B1")
  validated <- validate_waz_params(weight_kg = weight_kg,
                                   age_days = age_days,
                                   gest_days = gest_days,
                                   sex = sex,
                                   id = id)
  waz <- do.call(validated, what = gigs_waz_internal)
  categorise_wfa_internal(waz, outliers = outliers)
}

#' Get head size categories using multiple vectors and GIGS-recommended growth
#' standards
#'
#' @param headcirc_cm Numeric vector of length one or more with head
#'   circumference measurement(s) in cm.
#' @inheritParams compute_wasting
#' @inherit categorise_wasting params references return
#' @examples
#' # The first observation for each infant in `id` uses the INTERGROWTH-21st
#' #  Newborn Size standards; the next two use either the INTERGROWTH-21st
#' # Postnatal Growth standards or WHO Child Growth Standards.
#' compute_headsize(
#'   headcirc_cm = c(31.6, 40, 50, 31.6, 40, 50),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F"),
#'   id = factor(c("A", "A", "A", "B", "B", "B"))
#' )
#'
#' # If you don't specify `id`, the function will not identify that the fourth
#' # data point is a birth measurement, and will categorise it as microcephalic
#' # instead of normal
#' compute_headsize(
#'   headcirc_cm = c(31.6, 40, 50, 31.6, 40, 50),
#'   age_days = c(0, 100, 500, 2, 100, 500),
#'   gest_days = c(245, 245, 245, 280, 280, 280),
#'   sex = c("M", "M", "M", "F", "F", "F")
#' )
#' @inherit categorise_headsize details note references return
#' @export
compute_headsize <- function(headcirc_cm, age_days, gest_days, sex, id = NULL) {
  validated <- validate_hcaz_params(headcirc_cm = headcirc_cm,
                                    age_days = age_days,
                                    gest_days = gest_days,
                                    sex = sex,
                                    id = id)
  hcaz <- do.call(validated, what = gigs_hcaz_internal)
  categorise_headsize_internal(hcaz)
}

# SRR tags ---------------------------------------------------------------------
#' @srrstats {G1.0} Primary literature referenced where relevant for each
#'   function in this script.
#' @srrstats {G1.4} This file's functions are all documented with `{roxygen2}`.
#' @srrstats {G2.0} Each exported function passes its inputs to `validate_*()`
#'   functions, which enforce specific input lengths.
#' @srrstats {G2.0a, EA1.3} Documentation in this script explicitly references
#'   length of inputs. Single-length inputs are explicitly referenced in the
#'   documentation and checked in their respective functions.
#' @srrstats {G2.1, G2.1a, G2.2} Documentation explicitly notes expected data
#'   types, lengths, and expected values for univariate input.
#' @srrstats {G2.3, G2.3a, G2.3b} Univariate character inputs are restricted to
#'   specific inputs by `{checkmate}` calls in the `validate_*()` functions;
#'   these are case-sensitive and documented as such.
NULL
