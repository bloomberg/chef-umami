# Changelog

## [0.1.0]

Updates to support modern Chef.

- Specifically Chef 14.x and ChefDK 3.4.x.
- Replaces the export/upload mechanism with the push mechanism as it does all that work anyhow.
  - Honestly, the only thing being used by the previous export functionality was the Chef client config. The rest was waste.
- Updates `Umami::Client` to manage creating and ingesting the config we need.
- Adds `Umami::Policyfile::PolicyfileLock` as a convenience.
- Minor updates to address changes in Chef/ChefDK support and methods.
- Fixes up Rubocop support within Umami as well as that used for testing Umami itself.

## [0.0.6]
- Adds tests.
- Updates gem dependencies to use newer versions of Chef and ChefDK.
- Updates Travis configuration to install newer versions of gems.

## [0.0.5]
- Adds support for parsing options.
- Minor typo fixes.

## [0.0.4]
- Fixes a bug where two methods have the same name. Thanks @HarryYC.
- Adds `spec_helper.rb` for unit tests, cutting down on boilerplate in each unit test.
 - Includes test coverage report.

## [0.0.3]
- I have no recollection.

## [0.0.2]
- My dog ate my homework.

## [0.0.1] - 2017-08-07
- Initial release.
