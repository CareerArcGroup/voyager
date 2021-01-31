# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

include Voyager

config = SpecHelper::Config.new(Voyager::MicrosoftGraphClient)

describe MicrosoftGraphClient do
  it 'generates the expected authorization url' do
    url = config.client.authorize_url('https://example.com/callback', scope: %w[profile mail name Files.Read.All], state: 'state123')
    uri = URI.parse(url)
    query = URI.decode_www_form(uri.query).to_h

    expect(uri.scheme).to eq('https')
    expect(uri.host).to eq('login.microsoftonline.com')
    expect(uri.path).to eq('/common/oauth2/v2.0/authorize')
    expect(query['client_id']).to eq(config.client.client_id)
    expect(query['state']).to eq('state123')
    expect(query['redirect_uri']).to eq('https://example.com/callback')
  end

  context 'with valid credentials' do
    it 'is authorized' do
      expect(config.client).to be_authorized
    end

    describe '#account_info' do
      it 'returns information about the user' do
        response = config.client.account_info

        expect(response).to be_successful
        expect(response.data['userPrincipalName']).not_to be_nil
      end
    end

    describe '#drives' do
      it 'returns a list of drives the user has access to' do
        response = config.client.drives

        expect(response).to be_successful
        expect(response.data['value'].count { |drive| drive['name'] == 'OneDrive'}).to eq(1)
      end
    end

    describe '#drive' do
      it 'returns the user\'s OneDrive drive' do
        response = config.client.drive

        expect(response).to be_successful
        expect(response.data['name']).to eq('OneDrive')
      end
    end

    describe '#drive_items' do
      it 'returns items within the user\'s OneDrive drive' do
        response = config.client.drive_items

        expect(response).to be_successful

        # expects there to be at least one drive item in the connected account's OneDrive
        # if this fails, you may need to add a file/folder
        expect(response.data['value'].map { |drive_item| drive_item['name'] }).not_to be_empty
      end
    end
  end
end
