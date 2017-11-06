# `umami`

A tool that attempts to write unit and integration tests for Chef cookbooks and
policies, making it easier to do the right thing and test code.

Let's see it in action!

[![asciicast](https://asciinema.org/a/138816.png)](https://asciinema.org/a/138816)

## How does it Work?

`umami` loads up one or more cookbooks in a `chef-zero` instance, executes the
compile phase of a `chef-client` run, and reads the run context to get a list
of the resources that will be managed.

**NOTE**: `umami` does not perform convergence.

### Unit Tests

With the set of resources enumerated, `umami` will write out a set of ChefSpec
unit tests for the cookbook in which it's running. It determines the tests to
write by matching the current directory to resources derived from that cookbook.

### Integration Tests

`umami` writes Inspec-type integration tests for all the resources it has found.

### Spec Files

All test files are written to `spec/umami/`. If my cookbook is named `wutang`
and I have the following recipes:

```
├── recipes/
│   ├── bonds.rb
│   ├── default.rb
│   ├── financial.rb
│   └── stocks.rb
```

`umami` will write tests as follows (assuming the recipes are defined in the run list):

```
├── spec/
│   └── umami/
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

Install `chef-umami` from your favorite `gem` source via:

`chef exec gem install chef-umami`

## How do I use it?

From the top level of your cookbook, run `umami`:

`chef exec umami`

When it is finished, it will display the paths to the test files it has
written:

```
Generating a set of unit tests...
Running Rubocop over 'spec/umami/unit/recipes' to enforce styling...
Wrote the following unit test files:
    spec/umami/unit/recipes/bonds_spec.rb
    spec/umami/unit/recipes/default_spec.rb
    spec/umami/unit/recipes/financial_spec.rb
    spec/umami/unit/recipes/stocks_spec.rb

Generating a set of integration tests...
Running Rubocop over 'spec/umami/integration' to enforce styling...
Wrote the following integration tests:
    spec/umami/integration/wutang_bonds_spec.rb
    spec/umami/integration/wutang_default_spec.rb
    spec/umami/integration/wutang_financial_spec.rb
    spec/umami/integration/wutang_stocks_spec.rb
```

### Running Unit Tests

Running one or more unit tests should be as easy as calling `rspec` on a given
test file, like so:

`chef exec rspec spec/umami/unit/recipes/default_spec.rb`

### Running Integration Tests

It's preferred to use `kitchen verify` to execute all integration tests.
Teach `kitchen` to run `umami`'s tests by updating `.kitchen.yml`. Specify
the appropriate `verifier` (`inspec`) and, if needed, direct `kitchen` where
the tests are located:

```
verifier:
  name: inspec

suites:
  - name: default
    provisioner:
      policyfile: Policyfile.rb
    ...
    verifier:
      inspec_tests:
        - path: spec/umami/integration
```

## Features

### OS Detection

ChefSpec may need to mock up ohai data (via Fauxhai). To facilitate this,
ChefSpec needs to be told what operating system to pretend to be. `umami`
does its best to detect the OS it's being called on.

### Styling

`umami` calls on Rubocop to perform some basic styling on test files after
they've been written. This makes it very easy to add testing methods to `umami`
without worrying about what the resulting indentation will be.

## Dependencies and Assumptions

`umami` depends on ChefDK to do the bulk of the work resolving cookbooks and
their dependencies. Further, `umami` assumes you're using Policyfile to manage
the run list.

## Caveats

`umami` is still in early and rapid development. Expect to see lots of activity.

`umami` **always overwrites the contents of `spec/umami` on each run.** This may
change in the future. Until then, you may want to move the generated tests
into a different subdirectory (i.e. `test/`).

`umami` is not aware of any context. For example, if a recipe includes another
recipe based on some condition (i.e. operating system), `umami` won't know about
it and therefore won't write a relevant test. `umami` knows about the resources
it finds during the compile phase of a `chef-client` run only. One can choose
to use one, many, all, or none of the tests. It's up to you to decide what, if
anything, you want to use.

`umami`'s goal is to help get you started writing and using tests in your
development cycle. It tries its best to provide a useful set of tests that you
can build on. **Do NOT depend solely on `umami` to provide test coverage!**

## Inspiration and Thanks

This project came to be largely out of fear of having to write a lot of test
code from scratch where none had previously existed. The idea of starting from
nothing seemed so daunting that it's likely no one would ever get started. I
wanted to give Chef developers a means to expedite writing tests. After all,
it's much easier to modify code than it is to write it in the first place.

`umami` is the product of research into various projects' code, such as
Chef, ChefDK, and Test Kitchen. I am grateful to everyone that has contributed
to those projects. `umami` borrows some patterns from those projects and, in
some cases, bits of code.
