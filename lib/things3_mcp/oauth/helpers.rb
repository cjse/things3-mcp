# frozen_string_literal: true

require 'rack'
require 'json'

module Things3Mcp
  module Oauth
    module Helpers
      NO_STORE = { 'cache-control' => 'no-store', 'pragma' => 'no-cache' }.freeze

      def json(status, body, headers = {})
        [status, { 'content-type' => 'application/json' }.merge(NO_STORE).merge(headers), [JSON.generate(body)]]
      end

      def oauth_error(status, error, description = nil)
        body = { error: error }
        body[:error_description] = description if description
        json(status, body)
      end

      def html(status, body)
        [status, { 'content-type' => 'text/html; charset=utf-8' }.merge(NO_STORE), [body]]
      end

      def self.base64url(bytes)
        [bytes].pack('m0').tr('+/', '-_').delete('=')
      end

      def h(text)
        Rack::Utils.escape_html(text.to_s)
      end
    end
  end
end
