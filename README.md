# Enu

This gem introduces missing [enumerated type](https://en.wikipedia.org/wiki/Enumerated_type) for Ruby and Rails.

Purpose and features:

- Unify enum types definition for Rails model attributes, compatible with ActiveRecord's [enum declarations](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html).
- Use structured constants instead of magic strings or numbers to address enum values.
- Keep track on enum references to simplify refactoring and codebase navigation.
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

### Enum types definition

Here is a basic example:

```ruby
# app/enums/post_status.rb
class PostStatus < Enu
  option :draft
  option :published
  option :moderated
  option :deleted
end
```

This class defines an enum type for a blog post status with a set of possible states: `draft`, `published`, `moderated` and `deleted`. Each state automatically receives integer representation: 0 for `draft`, 1 for `published`, and so on. The top defined option will be treated as the `default`.

It is also possible to specify explicit integer values for the options:

```ruby
class PostStatus < Enu
  option :draft, 10
  option :published, 20
end
```

Or mix implicit and explicit approach:

```ruby
class PostStatus < Enu
  option :draft, 10
  option :published
end
```

Enu will ensure there are no collisions in the option names and values.

### Using enums

Enu classes are compatible with ActiveRecord's [enum](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) declaration:

```ruby
class Post < ApplicationRecord
  enum status: PostStatus
end

# Use enum helpers as usual:
post = Post.create!    # => #<Post:...>
Post.draft?            # => true
post.published?        # => false
Post.published.to_sql  # => "SELECT "posts".* FROM "posts" WHERE "posts"."status" = 1"
```

Each Enu descendant inherits `options` class method, returning enum options representation in the form of a `Hash`. In addition the enumeration class delegates some `Hash` methods, so ActiveRecord can treat it as an actual hash. In the last example `enum status: PostStatus` call is equivalent to `enum status: PostStatus.options`:

```ruby
PostStatus.options    # => {:draft=>0, :published=>1, :moderated=>2, :deleted=>3}
PostStatus.each.to_h  # => {:draft=>0, :published=>1, :moderated=>2, :deleted=>3}
```

### Scoped constants

Sometimes ApplicationRecord helpers are not enough, and you need to address enum values directly. If this is the case, use scoped constants instead of magic strings values.

Each `option` definition generate corresponding value method in the `Enu` descendant:

```ruby
PostStatus.draft            # => :draft
PostStatus.published        # => :published
PostStatus.moderated        # => :moderated
PostStatus.deleted          # => :deleted

# First option definition is treated as the default
PostStatus.default          # => :draft
```

Integer representation is available as well:

```ruby
PostStatus.draft_value      # => 0
PostStatus.published_value  # => 1
PostStatus.moderated_value  # => 2
PostStatus.deleted_value    # => 3
```

Say, you need to update multiple attributes for a set of DB records with a single query:

```ruby
class User < ApplicationRecord
  has_many :posts
  # ...
end

user = User.first

if user.nasty_spammer?
  user.posts.update_all(
    status: PostStatus.moderated,
    moderated_by: current_user,
    moderation_reason: 'being a nasty spammer'
  )
end
```

Another example is a state machine definition with [aasm](https://github.com/aasm/aasm) gem. Here is the Post model, complemented with state transitions logic:

```ruby
class Post < ApplicationRecord
  include AASM

  enum status: PostStatus

  aasm column: :status, enum: true do
    state PostStatus.draft, initial: true
    state PostStatus.published
    state PostStatus.moderated
    state PostStatus.deleted

    # Draft posts can be published
    event :publish do
      transitions from: PostStatus.draft, to: PostStatus.published
    end

    # Published posts can be moderated
    event :moderate do
      transitions from: PostStatus.published, to: PostStatus.moderated
    end

    # Any post can be moved to trash (but only once)
    event :soft_delete do
      transitions from: PostStatus.keys.without(:deleted), to: PostStatus.deleted
    end
  end
end
```

Notice that `soft_delete` event is using `PostStatus.keys` shortcut, instead of declaring a separate transition for each available post status.

Now the `Post#state` field has a set of transition rules:

```ruby
post = Post.create!
post.status          # => :draft

post.publish!        # perform sample transition and persist the new status
post.status          # => :published

post.soft_delete!
post.status          # => :deleted
post.moderate!       # will raise an AASM::InvalidTransition, because deleted
                     # posts are not supposed to be moderated
```

### Inheriting enumerations

Enu descendants are immutable. In other words, after a class is declared, there is no way to change its set of options. Use inheritance to add more options:

```ruby
class AdvancedPostStatus < PostStatus
  option :pinned
  option :featured
end

pp AdvancedPostStatus.options

# {
#   :draft => 0,
#   :published => 1,
#   :moderated => 2,
#   :deleted => 3,
#   :pinned => 4,
#   :featured => 5
# }
```

### Tracking enum type references

Scoped constants help to track enum type references in the codebase. Looking up an enum class name or a specific value, like  `PostStatus.draft`, is a more efficient approach to navigate through code, comparing to a situation with plain string literals or symbols, like in the [Rails Guides examples](https://guides.rubyonrails.org/active_record_querying.html#enums). Chances are that search results for `draft` will be much noisier in a larger codebase.

### Structuring codebase

Notice that `PostStatus` class definition is located under `app/enums/` subdirectory. Keeping `Enu` classes in a separate location is not mandatory. Though, it will help to keep the project structure organized. In a typical Rails project [autoload mechanism](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-paths-and-eager-load-paths)  will resolve all constants in `app` subdirectories, so there is no need to worry about requiring anything manually.

### Namespaces

This readme uses `PostStatus` constant example, defined in the global namespace for the sake of brevity. In a larger real-life project it is worth considering to organize sibling classes with a module, instead of polluting root namespace:

```ruby
# app/enums/post_status.rb
module Enums
  class PostStatus < Enu
    # ...
  end
end
```

Default Rails autoload configuration will successfully resolve `Enums::PostStatus` as well.

#### Spring gotcha

There is a known issue with using custom directories in a Rails application. If you running your app with [Spring preloader](https://github.com/rails/spring) (which is true for default configuration), make sure to restart the preloader. Otherwise, Rails autoload will not resolve new constants under `app/enums/` or any other custom paths, and will keep raising `NameError`. This command will help:

```bash
> bin/spring stop
Spring stopped.
```

## Development

After checking out the repository, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dreikanter/enu. Before sending a PR, please make sure your changes are on a new branch forked from `dev`, and the test coverage is kept at 100%.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
