# frozen_string_literal: true

require 'json'
require 'digest'
require 'securerandom'
require 'fileutils'

module Things3Mcp
  module Oauth
    # Persists OAuth clients, codes, and tokens in one JSON file. Only hashes of
    # secrets touch disk. All access goes through one lock.
    class Store
      CODE_TTL = 5 * 60
      ACCESS_TTL = 60 * 60
      REFRESH_TTL = 30 * 24 * 60 * 60

      def initialize(path)
        @path = path
        @lock = Mutex.new
        @data = load
      end

      # -- clients ---------------------------------------------------------------

      def register_client(redirect_uris:, client_name: nil)
        id = SecureRandom.urlsafe_base64(16)
        write do |d|
          d['clients'][id] = { 'redirect_uris' => redirect_uris, 'client_name' => client_name, 'created_at' => now }
        end
        id
      end

      def client(id)
        read { |d| d['clients'][id] }
      end

      # -- authorization codes ---------------------------------------------------

      def issue_code(client_id:, redirect_uri:, code_challenge:, scope:, resource:)
        code = SecureRandom.urlsafe_base64(32)
        write do |d|
          d['codes'][digest(code)] = {
            'client_id' => client_id, 'redirect_uri' => redirect_uri, 'code_challenge' => code_challenge,
            'scope' => scope, 'resource' => resource, 'expires_at' => now + CODE_TTL
          }
        end
        code
      end

      # Removes and returns the code record, or nil when unknown or expired.
      def consume_code(code)
        write { |d| take(d['codes'], code) }
      end

      # -- tokens ----------------------------------------------------------------

      def issue_tokens(client_id:, scope:)
        access = SecureRandom.urlsafe_base64(32)
        refresh = SecureRandom.urlsafe_base64(32)
        write do |d|
          d['access_tokens'][digest(access)] = { 'client_id' => client_id, 'scope' => scope, 'expires_at' => now + ACCESS_TTL }
          d['refresh_tokens'][digest(refresh)] = { 'client_id' => client_id, 'scope' => scope, 'expires_at' => now + REFRESH_TTL }
        end
        { access_token: access, refresh_token: refresh, expires_in: ACCESS_TTL, scope: scope }
      end

      def access_token(token)
        read { |d| live(d['access_tokens'][digest(token)]) }
      end

      def consume_refresh_token(token)
        write { |d| take(d['refresh_tokens'], token) }
      end

      private

      def read
        @lock.synchronize { yield @data }
      end

      def write
        @lock.synchronize do
          result = yield @data
          prune
          save
          result
        end
      end

      def take(table, secret)
        record = table.delete(digest(secret))
        live(record)
      end

      def live(record)
        record if record && record['expires_at'].to_i > now
      end

      def prune
        %w[codes access_tokens refresh_tokens].each do |table|
          @data[table].delete_if { |_, r| r['expires_at'].to_i <= now }
        end
      end

      def digest(secret)
        Digest::SHA256.hexdigest(secret.to_s)
      end

      def now
        Time.now.to_i
      end

      def empty
        { 'clients' => {}, 'codes' => {}, 'access_tokens' => {}, 'refresh_tokens' => {} }
      end

      def load
        return empty unless File.exist?(@path)

        empty.merge(JSON.parse(File.read(@path)))
      rescue JSON::ParserError
        empty
      end

      def save
        FileUtils.mkdir_p(File.dirname(@path))
        tmp = "#{@path}.tmp"
        File.write(tmp, JSON.pretty_generate(@data))
        File.chmod(0o600, tmp)
        File.rename(tmp, @path)
      end
    end
  end
end
