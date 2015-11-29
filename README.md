# gene

Gene = Generic Data Format

## Tasks

- [ ] Define a core set of functionalities(e.g. data types, control structures) to be handled by a core interpreter

  - [ ] set / use variables
  - [ ] if / else
  - [ ] for / each / repeat / while
  - [ ] define / call blocks
  - [ ] scoped variables (global + local)
  - [ ] environment variables (not applicable if running inside browser ?!)
  - [ ] feature detection
  - [ ] Multiple run of interpretation (potential performance issue?):
    * First run: core types interpreter (handle array, hash, ...)
    * Second run: macros interpreter (handle #SET, #IF, ...)
    * Third run: target language interpreter (ruby/js/...)

- [ ] Output of the core interpreter can be consumed by specialized interpreters (e.g. Ruby interpreter)

  - [ ] Specialized interpreters will inherit and override handlers from core interpreter

## Contributing to gene

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Guoliang Cao. See LICENSE.txt for further details.

