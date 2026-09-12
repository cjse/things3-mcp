# frozen_string_literal: true

require 'rack'
require 'mcp'
require_relative 'config'
require_relative 'token_auth'
require_relative '../oauth/store'
require_relative '../oauth/metadata'
require_relative '../oauth/register'
require_relative '../oauth/authorize'
require_relative '../oauth/token'

module Things3Mcp
  module Http
    # Builds the Rack application: OAuth endpoints plus the guarded MCP transport.
    module App
      module_function

      def build(config: Config.from_env, store: nil, server: nil)
        store ||= Oauth::Store.new(File.join(config.data_dir, 'oauth.json'))
        server ||= Things3Mcp::Server.build
        transport = MCP::Server::Transports::StreamableHTTPTransport.new(
          server,
          stateless: true,
          allowed_hosts: [config.host]
        )

        Rack::Builder.new do
          map('/.well-known') { run Oauth::Metadata.new(config) }
          map('/register') { run Oauth::Register.new(store) }
          map('/authorize') { run Oauth::Authorize.new(store, config) }
          map('/token') { run Oauth::Token.new(store) }
          map('/mcp') do
            use TokenAuth, config: config, store: store
            run transport
          end
          map('/') do
            run ->(_env) { [200, { 'content-type' => 'text/plain' }, ["things3-mcp #{Things3Mcp::VERSION}. MCP endpoint: #{config.mcp_url}\n"]] }
          end
        end.to_app
      end
    end
  end
end
