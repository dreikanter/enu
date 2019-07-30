# Enu

[![Build Status](https://travis-ci.org/dreikanter/enu.svg?branch=master)](https://travis-ci.org/dreikanter/enu)

This gem introduce missing enum type for Ruby and Rails.

Purpose and features:

- Unify enum types definition for Rails model attributes, compatible with ActiveRecord's [enum declarations](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html).
- Use constants instead of magic strings or numbers to define enum values.
- Support explicit and implicit enum options definition.
- Keep track on enum references to simplify refactoring.
- Provide a standardized way to export enum definitions to client-side JavaScript modules, managed by either  Webpack or Rails Assets Pipeline.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'enu'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install enu
```

## Usage

[TODO]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dreikanter/enu. Before sending a PR, please make sure your changes are on a new branch forked from `dev`, and the test coverage is kept at 100%.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
