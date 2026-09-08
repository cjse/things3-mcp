# frozen_string_literal: true

require 'uri'

module Things3Mcp
  module Http
    # Settings for the HTTP server, read from the environment.
    class Config
      attr_reader :public_url, :login_password, :auth_token, :data_dir

      def self.from_env(env = ENV)
        new(
          public_url: env.fetch('MCP_PUBLIC_URL', "http://127.0.0.1:#{env.fetch('PORT', '9292')}"),
          login_password: env['MCP_LOGIN_PASSWORD'],
          auth_token: env['MCP_AUTH_TOKEN'],
          data_dir: env.fetch('MCP_DATA_DIR', File.expand_path('../../../data', __dir__))
        )
      end

      def initialize(public_url:, login_password:, auth_token: nil, data_dir:)
        @public_url = public_url.to_s.sub(%r{/+\z}, '')
        @login_password = blank?(login_password) ? nil : login_password
        @auth_token = blank?(auth_token) ? nil : auth_token
        @data_dir = data_dir
        raise ArgumentError, 'MCP_PUBLIC_URL must be an http(s) URL' unless @public_url.match?(%r{\Ahttps?://})
        raise ArgumentError, 'MCP_LOGIN_PASSWORD is required' if @login_password.nil?
      end

      def host
        URI(public_url).host
      end

      def mcp_url = "#{public_url}/mcp"
      def resource_metadata_url = "#{public_url}/.well-known/oauth-protected-resource"

      private

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
