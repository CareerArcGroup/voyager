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

  before do
    config.client.refresh!
  end

  let(:search_body) do
    { "requests": [{ "entityTypes": ["driveItem"], "query": { "queryString": "CareerArc" }}] }
  end

  let(:search_data) { config.client.search(body: search_body).data }
  let(:search_hits) { search_data['value'].first['hitsContainers'].first['hits'] }
  let(:drive_item)  { search_hits.first['resource'] }
  let(:drive_item_ids) do
    {
      drive_id: drive_item.dig('parentReference', 'driveId'),
      item_id: drive_item['id']
    }
  end

  let(:sharepoint_ids) do
    all_sharepoint = drive_item.dig('parentReference', 'sharepointIds')
    {
      site_id: drive_item.dig('parentReference', 'siteId'),
      list_id: all_sharepoint['listId'],
      item_id: all_sharepoint['listItemUniqueId']
    }
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

    describe '#search' do
      it 'queries the search API' do
        config.client.refresh!
        body = {:requests=>[{:entityTypes=>["drive"], :query=>{:queryString=>"careerarc"}}]}
        response = config.client.search(body: body)

        hits = response.data['value'].first['hitsContainers'].first['hits']
        types = hits.map { |h| h.dig('resource', '@odata.type') }.uniq

        expect(response).to be_successful
        expect(hits.empty?).to be false
        expect(types.all?{|t| t == '#microsoft.graph.drive'}).to be true
      end
    end

    describe '#my_drives' do
      it 'returns a list of drives the user has access to' do
        response = config.client.my_drives

        expect(response).to be_successful
        expect(response.data['value'].count { |drive| drive['name'] == 'OneDrive'}).to eq(1)
      end
    end

    describe '#my_drive_children' do
      it 'returns the user\'s OneDrive drive' do
        response = config.client.my_drive_children

        expect(response).to be_successful
        expect(response.data['value'].first['name']).not_to be_nil
      end
    end

    describe '#my_drive_items' do
      it 'returns items within the user\'s OneDrive drive' do
        response = config.client.my_drive_items

        expect(response).to be_successful

        # expects there to be at least one drive item in the connected account's OneDrive
        # if this fails, you may need to add a file/folder
        expect(response.data['value'].map { |drive_item| drive_item['name'] }).not_to be_empty
      end
    end

    describe '#drive_following' do
      it 'returns a list of drives the authed user follows' do
        response = config.client.drive_following

        expect(response).to be_successful
      end
    end

    describe '#drive_shared' do
      it 'returns a list of drives the authed user follows' do
        response = config.client.drive_shared

        expect(response).to be_successful
      end
    end

    describe '#drive' do
      it 'returns a list of a given drive\'s contents' do
        response = config.client.drive(drive_item_ids[:drive_id])

        expect(response).to be_successful
        expect(response.data['id']).to eq(drive_item_ids[:drive_id])
      end

      it 'appends expansions and select options if given' do
        response = config.client.drive(drive_item_ids[:drive_id], '?expand=list')

        expect(response).to be_successful
        expect(response.data['list']).not_to be_empty
      end
    end

    describe '#drive_children' do
      it 'returns a list of children for a given drive' do
        response = config.client.drive_children(drive_item_ids[:drive_id])

        expect(response).to be_successful
        expect(result = response.data['value'].first['name']).not_to be_nil
      end
    end

    describe '#drive_item' do
      it 'queries a particular item in a given drive' do
        response = config.client.drive_item(drive_item_ids[:drive_id], drive_item_ids[:item_id])

        expect(response).to be_successful
        expect(response.data.dig('parentReference', 'driveId')).to eq drive_item_ids[:drive_id]
      end

      it 'returns expanded and selected fields if given' do
        response = config.client.drive_item(drive_item_ids[:drive_id], drive_item_ids[:item_id], '?expand=thumbnails')

        expect(response).to be_successful
        expect(response.data.member?('thumbnails')).to be true
      end
    end

    describe '#list' do
      it 'returns a given list\'s data, given a site_id' do
        response = config.client.list(sharepoint_ids[:site_id], sharepoint_ids[:list_id])

        expect(response).to be_successful
      end

      it 'returns expanded and selected fields if given' do
        response = config.client.list(sharepoint_ids[:site_id], sharepoint_ids[:list_id], '?expand=items')

        expect(response).to be_successful
        expect(response.data.member?('items')).to be true
      end
    end

    describe '#list_item' do
      it 'returns a particular item in a given list' do
        args = [sharepoint_ids[:site_id], sharepoint_ids[:list_id], sharepoint_ids[:item_id]]
        response = config.client.list_item(*args)

        expect(response).to be_successful
        expect(response.data['fields']).not_to be_empty
      end
    end
  end
end
