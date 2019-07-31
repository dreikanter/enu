# Enu

⚠️ WARNING! This implementation is experimental. Please do not use in production before stable release is announced.

This gem introduces missing [enumerated type](https://en.wikipedia.org/wiki/Enumerated_type) for Ruby and Rails.

Purpose and features:

- Unify enum types definition for Rails model attributes, compatible with ActiveRecord's [enum declarations](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html).
- Use structured constants instead of magic strings or numbers to define enum values.
- Keep track on enum references to simplify refactoring.
- Support explicit and implicit enum options definition.
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

This class defines an enum type for a blog post status which four optional states: `draft`, `published`, `moderated` and `deleted`. Each state automatically receives integer representation: 0 for `draft`, 1 for `published`, and so on. The first option will be treated as `default`.

### Using enums

After enum type is defined, it is possible to use it in a Rails model:

```ruby
# app/models/post.rb
#
# Table name: posts
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  status           :integer          default(0), not null
#  ...
#
class Post < ApplicationRecord
  enum status: PostStatus.options
  # ...
end
```

`options` class method will return enum representation in the form of a `Hash`, compatible with [ActiveRecord::Enum](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) declaration:

```ruby
PostStatus.options  # {"draft"=>0, "published"=>1, "moderated" => 2, "deleted"=>3}
```

Use [enum helpers](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) as usual:

```ruby
Post.new.draft?        # true
Post.new.published?    # false

post = Post.create!    # #<Post:...>
post.draft?            # true
post.published!        # true
post.status            # "published"

Post.published.to_sql  # "SELECT "posts".* FROM "posts" WHERE "posts"."status" = 1"
```

### Scoped constants

Sometimes native helper methods are not enough, and you need to address enum values directly. If this is the case, use scoped constants instead of magic strings values. Say, you need to update multiple attributes for a set of DB records with a single query:

```ruby
# app/models/user.rb
#
# Table name: posts
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  ...
#
class User < ApplicationRecord
  has_many :posts

  def nasty_spammer?
    # ...
  end
end

use = User.first

if user.nasty_spammer?
  user.posts.update_all(
    status: PostStatus.moderated,
    moderated_by: current_user,
    moderated_at: Time.new.utc,
    moderation_reason: 'being a nasty spammer'
  )
end
```

Another example is a state machine definition with [aasm](https://github.com/aasm/aasm) gem:

```ruby
class Post < ApplicationRecord
  include AASM

  enum status: PostStatus.options

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

    # Any post can be deleted (but only once)
    event :dump do
      transitions from: PostStatus.keys.without(:deleted), to: PostStatus.deleted
    end
  end
end
```

Notice that `dump` event is using `PostStatus.keys` shortcut, instead of declaring a separate transition for each available post status.  `Enu` provides `keys` and `values` class methods for each enum type.

Now the `Post#state` field has transition rules:

```ruby
post = Post.create!  # new record status will be initialized with "draft" value
post.status          # => "draft"

post.publish!        # performs sample transition and persist the new status
post.status          # => "published"

post.dump!
post.moderate!       # will raise an AASM::InvalidTransition, because deleted
                     # posts are not supposed to be moderated
```

### Code base navigation

Scoped constants will help to track enum type references in your codebase. Looking up an enum class name or a specific value, like  `PostStatus.draft`, is a more efficient way to navigate your codebase, comparing to a situation when you use plain string literals or symbols, like in the [Rails Guides examples](https://guides.rubyonrails.org/active_record_querying.html#enums). Chances are search results for `draft` will be much noisier in a large codebase.

Notice the source file location. Keeping enum type definitions in a separate location is not mandatory, though, it will help to keep the source code organized. In a typical Rails application project [autoload](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-paths-and-eager-load-paths) mechanism will resolve all constants in `app` subdirectories, so there is no need to worry about requiring anything manually.

This readme uses `PostStatus` for the sake of brevity. In a larger real-life code base, though, it is worth considering to organize sibling classes with a module, instead of polluting root namespace:

```ruby
# app/enums/post_status.rb
module Enums
  class PostStatus < Enu
    # ...
  end
end
```

Default Rails autoload configuration will successfully resolve `Enums::PostStatus` constant.

#### Spring gotcha

There is a known issue with using custom directories in a Rails application. If you running your app with [Spring preloader](https://github.com/rails/spring) (which is true for default configuration), make sure to restart the preloader. Otherwise, Rails autoload will not resolve any constants under `app/enums/` or any other custom paths, and will keep raising `NameError`. This command will help:

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
