# frozen_string_literal: true

require 'rack'
require 'json'

module Things3Mcp
  module Http
    # Guards /mcp. Accepts the static token or a live OAuth access token.
    class TokenAuth
      def initialize(app, config:, store:)
        @app = app
        @config = config
        @store = store
      end

      def call(env)
        token = bearer(env)
        return @app.call(env) if token && (static_ok?(token) || @store.access_token(token))

        unauthorized
      end

      private

      def bearer(env)
        header = env['HTTP_AUTHORIZATION'].to_s
        return nil unless header.start_with?('Bearer ')

        header.delete_prefix('Bearer ').strip
      end

      def static_ok?(token)
        expected = @config.auth_token
        return false unless expected

        token.bytesize == expected.bytesize && Rack::Utils.secure_compare(token, expected)
      end

      def unauthorized
        [
          401,
          {
            'content-type' => 'application/json',
            'www-authenticate' => "Bearer resource_metadata=\"#{@config.resource_metadata_url}\", scope=\"things\""
          },
          [JSON.generate({ jsonrpc: '2.0', error: { code: -32_000, message: 'Unauthorized' }, id: nil })]
        ]
      end
    end
  end
end
