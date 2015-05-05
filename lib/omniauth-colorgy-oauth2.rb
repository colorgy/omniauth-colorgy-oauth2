require File.join('omniauth', 'colorgy_oauth2')
require File.join('flash_message_reporter') if defined? ActiveSupport::Concern
require File.join('colorgy_devise_sso_manager') if defined? Devise && defined? ActiveSupport::Concern
