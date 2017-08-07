# Checklist for Open Source release
- [x] Add a [Changelog](http://keepachangelog.com/en/1.0.0/) to the project.
- [x] Add open source license (Apache-2.0) to project
  - [x] Headers at the top of source files with abbreviated copyright.
- [ ] Add travis configuration file for automated linting/testing
  - Take a look at the cookbook test-kitchen configuration for integration testing
  - Something along the lines of `gem build chef-ramsay.gemspec && chef gem install chef-ramsay*.gem`
