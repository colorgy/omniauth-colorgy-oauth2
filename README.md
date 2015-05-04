# OmniAuth Colorgy Strategy [![Build Status](https://travis-ci.org/colorgy/omniauth-colorgy-oauth2.svg?branch=master)](https://travis-ci.org/colorgy/omniauth-colorgy-oauth2)

Strategy to authenticate with Colorgy via OAuth2 in OmniAuth.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-colorgy-oauth2'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-colorgy-oauth2


## Usage

The OmniAuth strategy can be used just like many of the other strategies, like omniauth-facebook, omniauth-google-oauth2... etc. Here are some few examples:

### Rails middleware

An example for adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :colorgy, ENV['APP_ID'], ENV['APP_SECRET'],
                     scope: 'public email identity offline_access',
                     fields: [:id, :uuid, :email, :avatar_url, :primary_identity],
                     includes: [:primary_identity],
                     client_options: { site: 'https://colorgy.io' }
end
```

> The configurations used in the above example are introduced in the `Configuration` section below.

### Devise

First define your application id and secret in `config/initializers/devise.rb`:

```ruby
config.omniauth :colorgy, "COLORGY_APP_ID", "COLORGY_APP_SECRET"
```

Then add the following to `config/routes.rb` so the callback routes are defined:

```ruby
# This controller will be setup later in `app/controllers/users/omniauth_callbacks_controller.rb`
devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
```

Make sure your model is omniauthable. Generally this is `app/models/user.rb`:

```ruby
devise :omniauthable, :omniauth_providers => [:colorgy]
```

Then make sure your callbacks controller is setup:

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def colorgy
    auth = request.env['omniauth.auth']

    # This method will be implement later in your model (e.g. app/models/user.rb)
    @user = User.from_colorgy(auth, current_user)

    if @user.persisted?
      set_flash_message(:notice, :success, kind: 'Colorgy') if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.colorgy_data'] = auth
      redirect_to new_user_registration_path
    end
  end
end
```

Finally, implement the `from_colorgy` method for the User model in `app/models/user.rb`

```ruby
def self.from_colorgy(auth, signed_in_resource=nil)
  user = where(:email => auth.info.email).first_or_create! do |user|
    user.password = Devise.friendly_token[0,20]
  end

  return user
end
```

Now you can add an login link in your view using:

```ruby
<%= link_to "Sign in with Colorgy", user_omniauth_authorize_path(:colorgy) %>
```

## Configuration

You can configure several options, which you pass into the provider method: `scope`, `fields`, `includes` and `client_options`.

An example using devise in `config/initializers/devise.rb` is like:

```ruby
config.omniauth :colorgy, ENV['APP_ID'], ENV['APP_SECRET'],
                          scope: 'public email identity offline_access',
                          fields: [:id, :uuid, :email, :avatar_url, :primary_identity],
                          includes: [:primary_identity],
                          client_options: { site: 'https://colorgy.io' }
```

- `scope`: A space-separated list of permissions you want to request from the user. defaults to `public`, which only provides the user's `id`, `uuid`, `username`, `name` and profile pictures (`avatar_url` and `cover_photo_url`)
- `fields`: An array selecting the fields of user's infomation to be returned. This is really useful for making your API calls more efficient and fast.
- `includes`: An array to select includable related data (e.g. `primary_identity`, `organizations`) to be included with the user's infomation. It will be convenient that you won't have to make another API call to get the data.
- `client_options`: A hash to specify the client configurations. Set this to `{ site: 'https://server.url' }` to change the API server that you want to use.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new Pull Request.
