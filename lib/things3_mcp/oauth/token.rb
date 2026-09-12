# frozen_string_literal: true

require 'digest'
require_relative 'helpers'

module Things3Mcp
  module Oauth
    # The token endpoint: authorization_code with PKCE, and refresh_token with rotation.
    class Token
      include Helpers

      def initialize(store)
        @store = store
      end

      def call(env)
        request = Rack::Request.new(env)
        return [405, { 'allow' => 'POST' }, []] unless request.post?
        return oauth_error(400, 'invalid_request', 'Body must be application/x-www-form-urlencoded') unless request.form_data?

        params = request.POST
        case params['grant_type']
        when 'authorization_code' then exchange_code(params)
        when 'refresh_token' then refresh(params)
        else oauth_error(400, 'unsupported_grant_type')
        end
      end

      private

      def exchange_code(params)
        record = @store.consume_code(params['code'].to_s)
        return oauth_error(400, 'invalid_grant', 'Unknown or expired code') unless record
        return oauth_error(400, 'invalid_grant', 'client_id mismatch') unless record['client_id'] == params['client_id']
        return oauth_error(400, 'invalid_grant', 'redirect_uri mismatch') unless record['redirect_uri'] == params['redirect_uri']
        return oauth_error(400, 'invalid_grant', 'PKCE verification failed') unless pkce_ok?(params['code_verifier'], record['code_challenge'])

        json(200, token_response(@store.issue_tokens(client_id: record['client_id'], scope: record['scope'])))
      end

      def refresh(params)
        record = @store.consume_refresh_token(params['refresh_token'].to_s)
        return oauth_error(400, 'invalid_grant', 'Unknown or expired refresh token') unless record
        return oauth_error(400, 'invalid_grant', 'client_id mismatch') if params['client_id'] && record['client_id'] != params['client_id']

        json(200, token_response(@store.issue_tokens(client_id: record['client_id'], scope: record['scope'])))
      end

      def pkce_ok?(verifier, challenge)
        return false if verifier.to_s.empty? || challenge.to_s.empty?

        computed = Helpers.base64url(Digest::SHA256.digest(verifier))
        computed.bytesize == challenge.bytesize && Rack::Utils.secure_compare(computed, challenge)
      end

      def token_response(tokens)
        tokens.merge(token_type: 'Bearer')
      end
    end
  end
end
