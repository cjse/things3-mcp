# frozen_string_literal: true

require_relative 'helpers'

module Things3Mcp
  module Oauth
    # Serves RFC 9728 protected resource metadata and RFC 8414 authorization
    # server metadata.
    class Metadata
      include Helpers

      SCOPES = ['things'].freeze

      def initialize(config)
        @config = config
      end

      def call(env)
        request = Rack::Request.new(env)
        return [405, { 'allow' => 'GET' }, []] unless request.get? || request.head?

        case request.path_info
        when '/oauth-protected-resource', '/oauth-protected-resource/mcp'
          json(200, protected_resource, 'cache-control' => 'public, max-age=300')
        when '/oauth-authorization-server'
          json(200, authorization_server, 'cache-control' => 'public, max-age=300')
        else
          [404, {}, []]
        end
      end

      def protected_resource
        {
          resource: @config.mcp_url,
          authorization_servers: [@config.public_url],
          scopes_supported: SCOPES,
          bearer_methods_supported: ['header'],
          resource_name: 'Things 3 MCP'
        }
      end

      def authorization_server
        base = @config.public_url
        {
          issuer: base,
          authorization_endpoint: "#{base}/authorize",
          token_endpoint: "#{base}/token",
          registration_endpoint: "#{base}/register",
          scopes_supported: SCOPES,
          response_types_supported: ['code'],
          response_modes_supported: ['query'],
          grant_types_supported: %w[authorization_code refresh_token],
          token_endpoint_auth_methods_supported: ['none'],
          code_challenge_methods_supported: ['S256']
        }
      end
    end
  end
end
