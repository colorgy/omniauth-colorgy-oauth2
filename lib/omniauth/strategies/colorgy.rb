require File.expand_path(File.join('..', '..', 'colorgy_oauth2'), __FILE__)
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Colorgy < OmniAuth::Strategies::OAuth2
      include OmniAuth::Strategy

      CORE_URL = 'https://colorgy.io'

      option :includes, []
      option :fields, []

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
        @raw_info ||= access_token.get("/api/v1/me.json?include=#{includes_url_param}&fields=#{fields_url_param}").parsed
      end

      def fields_url_param
        @fields_url_param ||= options[:fields].is_a?(Array) ? options[:fields].join(',') : options[:fields]
      end

      def includes_url_param
        @includes_url_param ||= options[:includes].is_a?(Array) ? options[:includes].join(',') : options[:includes]
      end
    end
  end
end
