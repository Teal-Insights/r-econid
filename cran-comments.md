## R CMD check results

0 errors | 0 warnings | 0 note

* This is a new release.

>"The package’s DESCRIPTION file must show both the name and email address of a single designated maintainer (a person, not a mailing list)."- from the CRAN repository policies. So please change the Author and Maintainer field to a person and not a company.

The copyright holder is Teal Insights, LLC, but we have added 'aut', 'cre', and 'ctb' roles to indicate the individual persons involved in the package development, with L. Teal Emery as the maintainer ('cre').

> \dontrun{} should only be used if the example really cannot be executed (e.g. because of missing additional software, missing API keys, ...) by the user. That's why wrapping examples in \dontrun{} adds the comment ("# Not run:") as a warning for the user. Does not seem necessary. Please replace \dontrun with \donttest. Please unwrap the examples if they are executable in < 5 sec, or replace dontrun{} with \donttest{}. For more details: <https://contributor.r-project.org/cran-cookbook/general_issues.html#structuring-of-examples>

We've removed the `\dontrun{}` from the examples in `add_entity_pattern.R` and `reset_patterns.R`. Although the examples are both altering the parent environment, the changes they make should be cleaned up by the end of the second example. However, we had to edit the first example so that the environment changes it makes don't cause a breaking conflict with the second example.