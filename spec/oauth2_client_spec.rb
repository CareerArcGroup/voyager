require 'spec_helper'

describe Voyager::OAuth2Client do
  let(:client_class) do
    Class.new(Voyager::OAuth2Client) do
      def response_parser
        Voyager::JsonParser
      end
    end
  end

  let(:credentials) do
    {
      site: 'https://example.com',
      token_url: 'https://example.com/oauth/token',
      client_id: 'client-id',
      client_secret: 'client-secret'
    }
  end

  def build_client(extra = {})
    client_class.new(credentials.merge(extra))
  end

  def request_headers(client)
    client.send(:build_request, Voyager::Request.new(:get, URI('https://example.com/me'), '', {}))
  end

  # ============================================================================
  # Tokens
  # ============================================================================

  describe '#refresh_token' do
    it 'reads the configured refresh token' do
      expect(build_client(refresh_token: 'refresh-token').refresh_token).to eq('refresh-token')
    end

    it 'is nil when none was configured' do
      expect(build_client.refresh_token).to be_nil
    end
  end

  describe '#refresh!' do
    let(:client) { build_client(token: 'access-token', refresh_token: 'refresh-token') }

    let(:refreshed) do
      OAuth2::AccessToken.new(client.send(:oauth_client), 'new-access-token', refresh_token: 'new-refresh-token')
    end

    before { allow(client.send(:access_token)).to receive(:refresh!).and_return(refreshed) }

    it 'updates the token, the refresh token and the access token together' do
      client.refresh!

      expect(client.token).to eq('new-access-token')
      expect(client.refresh_token).to eq('new-refresh-token')
      expect(client.send(:access_token)).to be(refreshed)
    end

    it 'signs subsequent requests with the refreshed token' do
      client.refresh!

      expect(request_headers(client)['Authorization']).to eq('Bearer new-access-token')
    end

    it 'does nothing without a refresh token' do
      client = build_client(token: 'access-token')

      expect(client.refresh!).to be_nil
      expect(client.token).to eq('access-token')
    end
  end

  describe '#authorize' do
    let(:client) { build_client }

    let(:granted) do
      OAuth2::AccessToken.new(client.send(:oauth_client), 'granted-token', refresh_token: 'granted-refresh-token')
    end

    before { allow(client.send(:oauth_client).auth_code).to receive(:get_token).and_return(granted) }

    it 'records the token and refresh token from the exchange' do
      client.authorize('code', 'https://example.com/callback')

      expect(client.token).to eq('granted-token')
      expect(client.refresh_token).to eq('granted-refresh-token')
    end
  end

  describe 'filtered terms' do
    def filter(log, client)
      Voyager::Trace.filter(log, client.send(:filtered_terms))
    end

    it 'redacts the credentials of an Authorization: Basic header' do
      log = filter('Authorization: "Basic Y2xpZW50LWlkOmNsaWVudC1zZWNyZXQ="', build_client)

      expect(log).to eq('Authorization: "Basic [FILTERED]"')
    end

    it 'leaves content that merely mentions Basic alone' do
      expect(filter('text: Basic Plan', build_client)).to eq('text: Basic Plan')
    end

    it 'redacts the refresh token' do
      log = filter('grant_type=refresh_token&refresh_token=refresh-token', build_client(refresh_token: 'refresh-token'))

      expect(log).to eq('grant_type=refresh_token&refresh_token=[FILTERED]')
    end
  end
end
