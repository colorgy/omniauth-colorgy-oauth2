require File.join('omniauth', 'colorgy_oauth2')
OmniAuth.config.add_camelization('colorgy_oauth', 'ColorgyOAuth')
OmniAuth.config.add_camelization('colorgy_oauth2', 'ColorgyOAuth2')

require File.expand_path(File.join('..', '..', 'app', 'controllers', 'concerns', 'flash_message_reporter'), __FILE__) if defined? ActiveSupport::Concern
require File.expand_path(File.join('..', '..', 'app', 'controllers', 'concerns', 'colorgy_devise_sso_manager'), __FILE__) if defined? Devise && defined? ActiveSupport::Concern
