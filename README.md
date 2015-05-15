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

First define your **application id** and **secret** in `config/initializers/devise.rb`:

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


## Single-Sign On/Off (SSO) Support

_(Optional, only if you want a single sing in/out status synced with Colorgy core.)_

The Colorgy SSO system is implemented using **OAuth 2.0** as the authorization protocol and **Sign-on Status Tokens (SST)** as credential of the sign-on status of the user, achieving sign in and out seamlessly controlled by a central server.

The **Sign-on Status Token (SST)** is stored in an cross-domain cookie (`_sst`) to represent the sign on status of the current user. **SST**s are trully [JSON Web Tokens (JWT)](https://tools.ietf.org/html/draft-ietf-oauth-json-web-token) containing identification information, signed by a RSA private key. Clients (other services under this SSO system) will be able to decode and verify the infomation using a corresponding RSA public key, and make reasonable reactions (signs in or out the user, reauthorize from the server... etc.) according to the infomation it provided.

This gem has implemented some solutions to cover certain use cases.

### Using Devise With Rails: `ColorgyDeviseSSOManager`

_An `ActiveSupport::Concern` to drop into your `ActionController` directly without any configurations to enable SSO support, if you're using devise and omniauth already._

> Limitations: since this tactic relys on sharing a cookie accross Colorgy core and your app, your app should be running on a subdomain of Colorgy core to make this work.

First, make sure Devise is setup properly to OmniAuth with Colorgy - clicking the 'Sign in with Colorgy' link will sign you in with no doubts.

Then confirm that you have at least copy down the **`uuid`** (and accessable via `User#uuid`) or `id` (accessable via `User#sid` or `User#cid`) property of a user when they are signing in from Colorgy Core. A sample is as below:

```ruby
# /app/models/user.rb

# ...

  def self.from_colorgy(auth, signed_in_resource=nil)
    # The uuid is copied down during creation!
    user = where(:uuid => auth.info.uuid).first_or_create! do |user|
      user.email = auth.info.email
    end
  end

# ...
```

You might want your local user data to be updated automatically when the core data is. If so, add a **`refreshed_at`** column to your User model and let your application be able to determine whether a refresh is needed (comparing the `update_at` in SST and this column):

```bash
rails g migration add_refreshed_at_to_users refreshed_at:datetime
rake db:migrate
```

Make sure it is updated while each core sign in, usually in `app/models/user.rb`:

```ruby
def self.from_colorgy(auth)
  # ...

  user.refreshed_at = Time.now
  user.save!

  # ...
end
```

Then just include `ColorgyDeviseSSOManager` in your ApplicationController and all the rest is done:

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  include ColorgyDeviseSSOManager
  include FlashMessageReporter
end
```

_`FlashMessageReporter` is optional, include it if you want to relay flash messages from core to your app ._

> This `ActiveSupport::Concern` is zero-configured since we can guess the URL of Core SSO by OmniAuth and Devise configurations, get the RSA public key automatically from the server, and use the User model's `uuid` (or `cid`, `sid`) and `refreshed_at` (or `synced_at`) by convention to perform certain actions like checking the user's identity or last refresh date.

> You can also manually specify the RSA public key used to verify SSTs. Just pass it in using an environment variable called **`CORE_RSA_PUBLIC_KEY`**. Put it in your `.env` or export it like this: `export CORE_RSA_PUBLIC_KEY='-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3D ... P2QIDAQAB\n-----END PUBLIC KEY-----\n'`. Make sure it's accessible via `ENV['CORE_RSA_PUBLIC_KEY']` in your app.

Now that users on your app will be signing in/out synchronizedly with Colorgy core, and is automatically reauthorized to get user's new data from core when updated.

`ColorgyDeviseSSOManager` also provide two URL helper methods: `sign_out_url`, `logout_url` pointed to the core sign out URL. You can replace your orginal logout link (maybe `destroy_user_session_path`) with these. (Since it's an SSO, signing out of the core server means to sign out of your application too.)

```ruby
<%= link_to("Log Out", sign_out_url, method: :delete) %>
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

The test suite can be run by executing `bundle exec rake`.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new Pull Request.
