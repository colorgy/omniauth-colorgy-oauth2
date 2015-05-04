require File.expand_path(File.join('..', '..', 'colorgy_oauth2'), __FILE__)
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Colorgy < OmniAuth::Strategies::OAuth2
      include OmniAuth::Strategy

      CORE_URL = 'https://colorgy.io'

      option :client_options, {
        :site => CORE_URL,
        :authorize_url => "/oauth/authorize"
      }

      uid do
        raw_info['uuid']
      end

      info do
        raw_info
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v1/me.json').parsed
      end
    end
  end
end
