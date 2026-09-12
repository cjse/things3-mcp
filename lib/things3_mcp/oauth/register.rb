# frozen_string_literal: true

require_relative 'helpers'

module Things3Mcp
  module Oauth
    # RFC 7591 dynamic client registration, restricted to Claude's redirect URIs.
    class Register
      include Helpers

      ALLOWED_REDIRECTS = [
        %r{\Ahttps://claude\.ai/api/mcp/auth_callback\z},
        %r{\Ahttp://localhost(:\d+)?/callback\z},
        %r{\Ahttp://127\.0\.0\.1(:\d+)?/callback\z}
      ].freeze

      def self.allowed_redirect?(uri)
        ALLOWED_REDIRECTS.any? { |pattern| uri.to_s.match?(pattern) }
      end

      def initialize(store)
        @store = store
      end

      def call(env)
        request = Rack::Request.new(env)
        return [405, { 'allow' => 'POST' }, []] unless request.post?

        body = JSON.parse(request.body.read)
        uris = Array(body['redirect_uris']).select { |u| self.class.allowed_redirect?(u) }
        return oauth_error(400, 'invalid_redirect_uri', 'Only Claude redirect URIs are accepted') if uris.empty?

        id = @store.register_client(redirect_uris: uris, client_name: body['client_name'])
        json(201, {
          client_id: id,
          client_name: body['client_name'],
          redirect_uris: uris,
          token_endpoint_auth_method: 'none',
          grant_types: %w[authorization_code refresh_token],
          response_types: ['code']
        }.compact)
      rescue JSON::ParserError
        oauth_error(400, 'invalid_client_metadata', 'Body must be JSON')
      end
    end
  end
end
