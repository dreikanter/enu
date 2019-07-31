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

Here is a basic example:

```ruby
# app/enums/post_status.rb
module Enums
  class PostStatus < Enu
    option :draft
    option :published
    option :deleted
  end
end
```

This class defines and enum type for a blog post status, which can have three states: `draft`, `published`, and `deleted`. Each state automatically receives integer representation: 0 for `draft`, 1 for `published`, and so on. The first option will be treated as `default`.

Notice the `Enums` module definition, and source file location. Neither is mandatory for an `Enu` class definition, though, it is a good practice to group sibling classes, instead of polluting root namespace. Rails [autoload](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-paths-and-eager-load-paths) mechanism will find all source files in `app` subdirectories, so there is no need to worry about enum classes resolution.

After enum type is defined, it is possible to use it in a Rails model:

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  enum status: Enums::PostStatus.options
end
```

`options` class method will return enum representation in the form of a `Hash`, compatible with [ActiveRecord::Enum](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) declaration:

```ruby
Enums::PostStatus.options  # => {"draft"=>0, "published"=>1, "deleted"=>3}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dreikanter/enu. Before sending a PR, please make sure your changes are on a new branch forked from `dev`, and the test coverage is kept at 100%.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
