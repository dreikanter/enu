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

This class defines an enum type for a blog post status with a set of possible states: `draft`, `published`, `moderated` and `deleted`. Each state automatically receives integer representation: 0 for `draft`, 1 for `published`, and so on. The top option will be treated as default.

It is also possible to specify explicit integer values:

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

Each `Enu` descendant inherits `options` class method, returning the options hash. In addition the enumeration class delegates some `Hash` methods, so ActiveRecord can treat it as an actual hash. In the last example `enum status: PostStatus` call is equivalent to `enum status: PostStatus.options`:

```ruby
PostStatus.options    # => {:draft=>0, :published=>1, :moderated=>2, :deleted=>3}
PostStatus.each.to_h  # => {:draft=>0, :published=>1, :moderated=>2, :deleted=>3}
```

### Scoped constants

Sometimes ApplicationRecord helpers are not enough, and you need to address enum values directly. If this is the case, use scoped constants instead of magic strings or symbol values.

Each `option` definition generates matching value method:

```ruby
PostStatus.draft            # => :draft
PostStatus.published        # => :published
PostStatus.moderated        # => :moderated
PostStatus.deleted          # => :deleted

# Top option definition is the default
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

Another example is a state machine definition with [AASM](https://github.com/aasm/aasm) gem. Here is the Post model, complemented with state transitions logic:

```ruby
class Post < ApplicationRecord
  include AASM
  enum status: PostStatus

  aasm column: :status, enum: true do
    state PostStatus.draft, initial: true
    state PostStatus.published
    # ...
  end
end
```

But let's make `aasm` block more compact by using `Object#tap`:

```ruby
class Post < ApplicationRecord
  include AASM
  enum status: PostStatus

  aasm column: :status, enum: true do
    PostStatus.tap do |ps|
      state ps.draft, initial: true
      state ps.published
      state ps.moderated
      state ps.deleted

      event :publish do
        transitions from: ps.draft, to: ps.published
      end

      event :unpublish do
        transitions from: ps.published, to: ps.draft
      end

      event :moderate do
        transitions from: ps.published, to: ps.moderated
      end

      event :soft_delete do
        transitions from: ps.keys.without(:deleted), to: ps.deleted
      end
    end
  end
end
```

Notice that `soft_delete` event uses `PostStatus.keys` shortcut, instead of declaring a separate transition for each post status.

Now the `Post#state` field has a set of transition rules:

```ruby
post = Post.create!
post.status     # => "draft"

post.publish!   # perform sample transition and persist the new status
post.status     # => "published"

post.soft_delete!
post.status     # => "deleted"
post.moderate!  # will raise an AASM::InvalidTransition, because deleted
                # posts are not supposed to be moderated
```

### Inheriting enumerations

Enu descendants are immutable. In other words, after a class is declared, there is no way to change it at runtime. Use inheritance to add more options:

```ruby
class AdvancedPostStatus < PostStatus
  option :pinned
  option :featured
end
```

Complemented enum hash will look like this:

```ruby
{
  :draft => 0,
  :published => 1,
  :moderated => 2,
  :deleted => 3,
  :pinned => 4,
  :featured => 5
}
```

### Tracking enums

Scoped constants help to look up enum type references in the code. Searching an enum class name or a specific value (i.e. `PostStatus.draft`) is a more efficient approach to navigation through the code, comparing to a situation with plain string literals or symbols, like in the [Rails Guides examples](https://guides.rubyonrails.org/active_record_querying.html#enums). Chances are that search results for "draft" will be much noisier in a larger codebase.

### Structuring type definitions

Notice that `post_status.rb`  is located under `app/enums/` subdirectory. Keeping enum classes in a separate location is not mandatory. Though, it will help to keep the project structure organized. Rails [autoload mechanism](https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-paths-and-eager-load-paths)  will resolve all constants in `app` subdirectories, so there is no need to worry about requiring anything manually.

### Namespaces

`PostStatus` example class is defined in the global namespace for the sake of brevity. In a larger real-life project it is worth considering to organize sibling classes with a module, instead of polluting root namespace:

```ruby
# app/enums/post_status.rb
module Enums
  class PostStatus < Enu
    # ...
  end
end
```

Default Rails autoload configuration will successfully resolve `Enums::PostStatus` as well.

### Spring gotcha

There is a known issue with using custom directories in a Rails application. If you running your app with [Spring preloader](https://github.com/rails/spring) (which is true for default configuration), make sure to restart the preloader. Otherwise, Rails autoload will not resolve new constants under `app/enums/` or any other custom paths, and will keep raising `NameError`. This command will help:

```bash
> bin/spring stop
Spring stopped.
```

### Export enum definition to JavaScript

Sometimes it is necessary to use same enum values on the client side, for instance, when you receive data object serializations from API. In this case it is possible to share your enum type definition with JavaScript code.

#### Webpack

Make sure you have [rails-erb-loader](https://github.com/usabilityhub/rails-erb-loader) installed and enabled so your Webpack configuration will process ERB properly. If you use [Webpacker](https://github.com/rails/webpacker) gem, run `bundle exec rails webpacker:install:erb`.

This example will export `PostStatus` enum to a JavaScript object:

```javascript
// app/javascript/src/enums.js.erb
export const postStatus = Object.freeze(<%= PostStatus.to_json %>)
```

`to_json` method generates JSON replresentation for the enum class options:

```json
{
  "draft": "draft",
  "published": "published",
  "moderated": "moderated",
  "deleted": "deleted"
}

```

Use generated object to reference enum values:

```javascript
import { postStatus } from 'enums'

postStatus.draft  // => "draft"
```

`Object.freeze()` call in the example above will prevent accidental change of the `postStatus` values. It is optional, though.

#### Rails Assets Pipeline

Same idea:

```javascript
// app/assets/javascripts/application.js

//= require_self
//= require_tree ./shared

window.App || (window.App = {});
```

```javascript
// app/assets/javascripts/shared/enums.js.erb

App.postStatus = Object.freeze(<%= PostStatus.to_json %>)
```

## Development

After checking out the repository, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dreikanter/enu. Before sending a PR, please make sure your changes are on a new branch forked from `dev`, and the test coverage is kept at 100%.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
