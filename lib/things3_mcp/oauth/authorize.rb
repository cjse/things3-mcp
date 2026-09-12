# frozen_string_literal: true

require 'erb'
require 'uri'
require_relative 'helpers'

module Things3Mcp
  module Oauth
    # The authorization endpoint. GET renders a password form. POST checks the
    # password and redirects back with a one-time code.
    class Authorize
      include Helpers

      PASSTHROUGH = %w[client_id redirect_uri response_type code_challenge code_challenge_method scope state resource].freeze
      TEMPLATE = ERB.new(File.read(File.join(__dir__, 'consent.html.erb')))
      FAILURE_DELAY = 1.0

      def initialize(store, config, delay: FAILURE_DELAY)
        @store = store
        @config = config
        @delay = delay
      end

      def call(env)
        request = Rack::Request.new(env)
        params = request.params.slice(*PASSTHROUGH)
        client = @store.client(params['client_id'])
        return html(400, page_error('Unknown client')) unless client
        return html(400, page_error('Redirect URI is not registered for this client')) unless client['redirect_uris'].include?(params['redirect_uri'])

        problem = validate(params)
        return redirect_error(params, problem) if problem

        if request.post?
          return grant(params, client) if password_ok?(request.params['password'])

          sleep(@delay)
          return html(401, render(params, client, error: 'Wrong password'))
        end

        html(200, render(params, client))
      end

      private

      def validate(params)
        return 'unsupported_response_type' unless params['response_type'] == 'code'
        return 'invalid_request' if params['code_challenge'].to_s.empty?
        return 'invalid_request' unless params['code_challenge_method'] == 'S256'

        nil
      end

      def password_ok?(given)
        expected = @config.login_password
        given = given.to_s
        given.bytesize == expected.bytesize && Rack::Utils.secure_compare(given, expected)
      end

      def grant(params, _client)
        code = @store.issue_code(
          client_id: params['client_id'], redirect_uri: params['redirect_uri'],
          code_challenge: params['code_challenge'], scope: params['scope'] || 'things',
          resource: params['resource']
        )
        query = { code: code }
        query[:state] = params['state'] if params['state']
        redirect(params['redirect_uri'], query)
      end

      def redirect_error(params, error)
        query = { error: error }
        query[:state] = params['state'] if params['state']
        redirect(params['redirect_uri'], query)
      end

      def redirect(uri, query)
        target = URI(uri)
        extra = URI.encode_www_form(query)
        target.query = [target.query, extra].compact.join('&')
        [302, { 'location' => target.to_s }.merge(NO_STORE), []]
      end

      # Variables and the h() helper visible to the template.
      View = Struct.new(:params, :client_name, :redirect_host, :error) do
        include Helpers

        def render_binding
          binding
        end
      end

      def render(params, client, error: nil)
        view = View.new(params, client['client_name'] || 'An MCP client', URI(params['redirect_uri']).host, error)
        TEMPLATE.result(view.render_binding)
      end

      def page_error(message)
        "<!doctype html><meta charset=\"utf-8\"><title>Error</title><p>#{h(message)}</p>"
      end
    end
  end
end
