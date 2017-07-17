# `ramsay`

A tool that attempts to write unit and integration tests for Chef cookbooks and
policies, making it easier to do the right thing and test code.

## How does it Work?

`ramsay` loads up one or more cookbooks in a `chef-zero` instance, executes the
compile phase of a `chef-client`, and reads the run context to get a list of the
resources that will be managed.

**NOTE**: `ramsay` does not perform convergence.

### Unit Tests

With the set of resources enumerated, `ramsay` will write out a set of ChefSpec
unit tests for the cookbook in which it's running. It determines the tests to
write by matching the current directory to resources derived from that cookbook.

### Integration Tests

Using either Serverspec or Inspec (coming soon), `ramsay` writes integration
tests for all the resources it has found.

### Spec Files

All test files are written to `spec/ramsay/`. If my cookbook is named `wutang`
and I have the following recipes:

```
├── recipes/
│   ├── bonds.rb
│   ├── default.rb
│   ├── financial.rb
│   └── stocks.rb
```

`ramsay` will write tests as follows:

```
├── spec/
│   └── ramsay/
│       ├── integration/
│       │   ├── wutang_bonds_spec.rb
│       │   ├── wutang_default_spec.rb
│       │   ├── wutang_financial_spec.rb
│       │   └── wutang_stocks_spec.rb
│       └── unit/
│           └── recipes/
│               ├── bonds_spec.rb
│               ├── default_spec.rb
│               ├── financial_spec.rb
│               └── stocks_spec.rb
```

## How do I get it?

Install `chef-ramsay` from your favorite `gem` source via:

`chef exec gem install chef-ramsay`

## How do I use it?

From the top level of your cookbook, run `ramsay`. It will

`chef exec ramsay`

When it is finished, it will display the paths to the test files it has
written:

```
Generating a set of unit tests...
Running Rubocop over 'spec/ramsay/unit/recipes' to enforce styling...
Wrote the following unit test files:
    spec/ramsay/unit/recipes/bonds_spec.rb
    spec/ramsay/unit/recipes/default_spec.rb
    spec/ramsay/unit/recipes/financial_spec.rb
    spec/ramsay/unit/recipes/stocks_spec.rb

Generating a set of integration tests...
Running Rubocop over 'spec/ramsay/integration' to enforce styling...
Wrote the following integration tests:
    spec/ramsay/integration/wutang_bonds_spec.rb
    spec/ramsay/integration/wutang_default_spec.rb
    spec/ramsay/integration/wutang_financial_spec.rb
    spec/ramsay/integration/wutang_stocks_spec.rb
```

## Features

### OS Detection

ChefSpec may need to mock up ohai data (via Fauxhai). To facilitate this,
ChefSpec needs to be told what operating system to pretend to be. `ramsay`
does its best to detect the OS it's being called on.

### Styling

`ramsay` calls on Rubocop to perform some basic styling on test files after
they've been written. This makes it very easy to add testing methods to `ramsay`
without worrying about what the resulting indentation will be.

## Caveats

`ramsay` is still in early and rapid development. Expect to see lots of activity.

`ramsay` is not aware of any context. For example, if a recipe includes another
recipe based on some condition (i.e. operating system), `ramsay` won't know about
it and therefore won't write a relevant test. `ramsay` knows about the resources
it finds during the compile phase of a `chef-client` run only. One can choose
to use one, many, all, or none of the tests. It's up to you to decide what, if
anything, you want to use.

`ramsay`'s goal is to help get you started writing and using tests in your
development cycle. It tries its best to provide a useful set of tests that you
can build on.

