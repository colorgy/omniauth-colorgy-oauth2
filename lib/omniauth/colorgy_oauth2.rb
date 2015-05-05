require "omniauth/colorgy_oauth2/version"
require File.join('omniauth', 'strategies', 'colorgy')
OmniAuth.config.add_camelization('colorgy_oauth', 'ColorgyOAuth')
OmniAuth.config.add_camelization('colorgy_oauth2', 'ColorgyOAuth2')

module OmniAuth
  module ColorgyOAuth2
    CORE_URL = 'https://colorgy.io'
  end
end
