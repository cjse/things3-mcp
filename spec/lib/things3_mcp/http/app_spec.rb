require 'spec_helper'
require 'rack/test'
require 'tmpdir'
require 'things3_mcp/http/app'

RSpec.describe Things3Mcp::Http::App do
  include Rack::Test::Methods

  let(:tmpdir) { Dir.mktmpdir }
  let(:config) do
    Things3Mcp::Http::Config.new(public_url: 'https://mac.example.ts.net', login_password: 'pw-secret',
                                 auth_token: 'static-token', data_dir: tmpdir)
  end
  let(:store) { Things3Mcp::Oauth::Store.new(File.join(tmpdir, 'oauth.json')) }
  let(:executor) { FakeExecutor.new(recs(rec('a1', 'Home', ''))) }
  let(:app) { described_class.build(config: config, store: store) }
  let(:redirect_uri) { 'https://claude.ai/api/mcp/auth_callback' }
  let(:verifier) { 'a' * 50 }
  let(:challenge) { Things3Mcp::Oauth::Helpers.base64url(Digest::SHA256.digest(verifier)) }

  before do
    Things3Mcp.client = Things3Mcp::Client.new(executor, Things3Mcp::DateParser.new)
    header 'Host', 'mac.example.ts.net'
  end

  after do
    Things3Mcp.client = nil
    FileUtils.rm_rf(tmpdir)
  end

  def register
    post '/register', JSON.generate(redirect_uris: [redirect_uri, 'https://evil.example/cb'], client_name: 'Claude'),
         'CONTENT_TYPE' => 'application/json'
    expect(last_response.status).to eq(201)
    JSON.parse(last_response.body)
  end

  def authorize(client_id, password: 'pw-secret', state: 'xyz')
    post '/authorize', {
      client_id: client_id, redirect_uri: redirect_uri, response_type: 'code',
      code_challenge: challenge, code_challenge_method: 'S256', state: state, scope: 'things',
      resource: config.mcp_url, password: password
    }
  end

  def exchange(client_id, code, code_verifier: verifier)
    post '/token', { grant_type: 'authorization_code', code: code, client_id: client_id,
                     redirect_uri: redirect_uri, code_verifier: code_verifier }
    JSON.parse(last_response.body)
  end

  def mcp_call(token, name = 'get_areas')
    post '/mcp', JSON.generate(jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: name, arguments: {} }),
         'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json, text/event-stream',
         'HTTP_AUTHORIZATION' => "Bearer #{token}"
  end

  describe 'metadata' do
    it 'serves protected resource metadata that names the MCP URL' do
      get '/.well-known/oauth-protected-resource'
      body = JSON.parse(last_response.body)
      expect(body['resource']).to eq('https://mac.example.ts.net/mcp')
      expect(body['authorization_servers']).to eq(['https://mac.example.ts.net'])
      get '/.well-known/oauth-protected-resource/mcp'
      expect(last_response.status).to eq(200)
    end

    it 'serves authorization server metadata with PKCE and DCR' do
      get '/.well-known/oauth-authorization-server'
      body = JSON.parse(last_response.body)
      expect(body).to include('issuer' => 'https://mac.example.ts.net', 'token_endpoint' => 'https://mac.example.ts.net/token',
                              'registration_endpoint' => 'https://mac.example.ts.net/register')
      expect(body['code_challenge_methods_supported']).to eq(['S256'])
      expect(body['token_endpoint_auth_methods_supported']).to eq(['none'])
    end
  end

  describe 'registration' do
    it 'keeps only allowed redirect URIs' do
      client = register
      expect(client['redirect_uris']).to eq([redirect_uri])
      expect(client['token_endpoint_auth_method']).to eq('none')
      expect(client).not_to have_key('client_secret')
    end

    it 'rejects clients with no allowed redirect URI' do
      post '/register', JSON.generate(redirect_uris: ['https://evil.example/cb']), 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to eq('invalid_redirect_uri')
    end

    it 'accepts Claude Code loopback URIs with any port' do
      expect(Things3Mcp::Oauth::Register.allowed_redirect?('http://localhost:3118/callback')).to be(true)
      expect(Things3Mcp::Oauth::Register.allowed_redirect?('http://127.0.0.1:65000/callback')).to be(true)
      expect(Things3Mcp::Oauth::Register.allowed_redirect?('http://localhost.evil.com/callback')).to be(false)
    end
  end

  describe 'authorization' do
    it 'renders the consent page with the client name and redirect host' do
      client_id = register['client_id']
      get '/authorize', client_id: client_id, redirect_uri: redirect_uri, response_type: 'code',
                        code_challenge: challenge, code_challenge_method: 'S256', state: 's'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Claude').and include('claude.ai').and include('name="state" value="s"')
    end

    it 'refuses an unregistered redirect URI without redirecting' do
      client_id = register['client_id']
      get '/authorize', client_id: client_id, redirect_uri: 'https://evil.example/cb', response_type: 'code',
                        code_challenge: challenge, code_challenge_method: 'S256'
      expect(last_response.status).to eq(400)
      expect(last_response.headers['location']).to be_nil
    end

    it 'redirects with an error when PKCE is missing' do
      client_id = register['client_id']
      get '/authorize', client_id: client_id, redirect_uri: redirect_uri, response_type: 'code', state: 's'
      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to eq("#{redirect_uri}?error=invalid_request&state=s")
    end

    it 'rejects a wrong password and does not issue a code' do
      app # build before stubbing delay
      allow_any_instance_of(Things3Mcp::Oauth::Authorize).to receive(:sleep)
      client_id = register['client_id']
      authorize(client_id, password: 'nope')
      expect(last_response.status).to eq(401)
      expect(last_response.body).to include('Wrong password')
    end
  end

  describe 'the full code flow' do
    it 'issues tokens, guards /mcp, rotates refresh tokens, and rejects reuse' do
      client_id = register['client_id']

      authorize(client_id)
      expect(last_response.status).to eq(302)
      location = URI(last_response.headers['location'])
      query = URI.decode_www_form(location.query).to_h
      expect(location.to_s).to start_with(redirect_uri)
      expect(query['state']).to eq('xyz')
      code = query['code']

      tokens = exchange(client_id, code)
      expect(last_response.status).to eq(200)
      expect(last_response.headers['cache-control']).to eq('no-store')
      expect(tokens).to include('token_type' => 'Bearer', 'expires_in' => 3600, 'scope' => 'things')

      # code is single use
      expect(exchange(client_id, code)['error']).to eq('invalid_grant')

      mcp_call(tokens['access_token'])
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body).dig('result', 'structuredContent', 'areas', 0, 'name')).to eq('Home')

      post '/token', { grant_type: 'refresh_token', refresh_token: tokens['refresh_token'], client_id: client_id }
      rotated = JSON.parse(last_response.body)
      expect(rotated['access_token']).not_to eq(tokens['access_token'])
      expect(rotated['refresh_token']).not_to eq(tokens['refresh_token'])

      post '/token', { grant_type: 'refresh_token', refresh_token: tokens['refresh_token'], client_id: client_id }
      expect(JSON.parse(last_response.body)['error']).to eq('invalid_grant')

      mcp_call(rotated['access_token'])
      expect(last_response.status).to eq(200)
    end

    it 'rejects a wrong PKCE verifier' do
      client_id = register['client_id']
      authorize(client_id)
      code = URI.decode_www_form(URI(last_response.headers['location']).query).to_h['code']
      expect(exchange(client_id, code, code_verifier: 'b' * 50)['error']).to eq('invalid_grant')
    end

    it 'survives a restart because tokens are persisted as hashes' do
      client_id = register['client_id']
      authorize(client_id)
      code = URI.decode_www_form(URI(last_response.headers['location']).query).to_h['code']
      access = exchange(client_id, code)['access_token']
      on_disk = File.read(File.join(tmpdir, 'oauth.json'))
      expect(on_disk).not_to include(access)
      expect(on_disk).to include(Digest::SHA256.hexdigest(access))

      reopened = Things3Mcp::Oauth::Store.new(File.join(tmpdir, 'oauth.json'))
      expect(reopened.access_token(access)).not_to be_nil
    end
  end

  describe '/mcp guard' do
    it 'returns 401 with a resource_metadata pointer when no token is given' do
      post '/mcp', '{}', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(401)
      expect(last_response.headers['www-authenticate']).to eq(
        'Bearer resource_metadata="https://mac.example.ts.net/.well-known/oauth-protected-resource", scope="things"'
      )
    end

    it 'accepts the static token' do
      mcp_call('static-token')
      expect(last_response.status).to eq(200)
    end

    it 'rejects an unknown token' do
      mcp_call('static-tokeN')
      expect(last_response.status).to eq(401)
      expect(executor.scripts).to be_empty
    end

    it 'rejects an unexpected Host header' do
      header 'Host', 'evil.example'
      mcp_call('static-token')
      expect(last_response.status).to eq(403)
    end
  end

  describe 'config' do
    it 'requires a login password' do
      expect { Things3Mcp::Http::Config.new(public_url: 'https://x', login_password: ' ', data_dir: tmpdir) }
        .to raise_error(ArgumentError, /MCP_LOGIN_PASSWORD/)
    end
  end
end
