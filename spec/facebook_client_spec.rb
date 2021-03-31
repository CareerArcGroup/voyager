
require 'spec_helper'
require 'yaml'
include Voyager

config = SpecHelper::Config.new(Voyager::FacebookClient)

describe FacebookClient do

  it "get an OK response from the Facebook test endpoint" do
    config.client.should be_connected
  end

  context "with valid Facebook credentials" do

    it "is authorized" do
      config.client.should be_authorized
    end

    it "can get user account info" do
      response = config.client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it 'can get user account image' do
      response = config.client.account_logo
      response.successful?.should be true
      response.data['data']['height'].should eq 200
    end

    it "can get a list of a users's albums" do
      response = config.client.albums
      response.successful?.should be true
      response.data["data"].nil?.should be false
    end

    it "can get a list of a page's albums" do
      response = config.client.albums(page_id: config.settings["page_id"])
      response.successful?.should be true
      response.data["data"].nil?.should be false
    end

    it "can retrieve a page access token" do
      response = config.client.page_access_token(config.settings["page_id"])

      response.successful?.should be true
      response.data["access_token"].nil?.should be false
    end

    it "can create a page tab" do
      token_response = config.client.page_access_token(config.settings["page_id"])
      access_token = token_response.data["access_token"]
      response = config.client.create_tab(config.settings["page_id"], app_id: config.credentials[:consumer_key], access_token: access_token)

      response.successful?.should be true
    end

    it "can post to a page with multiple images" do
      photos = [
        File.new(File.expand_path("../assets/ocean_portrait.jpg", __FILE__)),
        File.new(File.expand_path("../assets/fishing_cat.jpg", __FILE__))
        #File.new(File.expand_path("../assets/profile_banner.jpg", __FILE__)),
        #File.new(File.expand_path("../assets/Twitter-BG_2_bg-image.jpg", __FILE__))
      ]

      token_response = config.client.page_access_token(config.settings["page_id"])
      access_token = token_response.data["access_token"]

      ids = photos.each_with_index.map do |photo, index|
        response = config.client.upload_photo(photo, page_id: config.settings["page_id"], caption: "This is photo #{index} of #{photos.count}", published: false, access_token: access_token)
        response.successful?.should be true
        response.data["id"].nil?.should be false

        response.data["id"]
      end

      #ids = ["1875456715841075", "1875456739174406"]

      url = "https://www.careerarc.com/job-listing/the-job-window-enterprises-inc-jobs-marketing-assistant-27522892"

      response = config.client.share(page_id: config.settings["page_id"], message: "Testing multi-photo posts from dimension #{Random.rand(9999)+1}. See here: #{url}", attached_media: ids, access_token: access_token)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it 'can get locations' do
      token_response = config.client.page_access_token(config.settings["page_id"])
      access_token = token_response.data["access_token"]
      location_fields = 'id, name, name_with_location_descriptor, username, picture, access_token, category, link, location, parent_page'
      response = config.client.locations(fields: location_fields, limit: 1000, access_token: access_token)
      response.successful?.should be true
    end

    # TODO: write ticket to work on figuring out how to test it on voyager
    xit 'can get company info' do
      token_response = config.client.page_access_token(config.settings["page_id"])
      access_token = token_response.data["access_token"]
      response = config.client.company_info('/2432345', fields: 'id, name, name_with_location_descriptor, username, picture, access_token, category, link, location', access_token: access_token)
      response.successful?.should be true
    end
  end

  context "with invalid Facebook credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

  context "with invalid App Secret Proof" do
    it "is not authorized" do
      response = config.client.account_info(appsecret_proof: "DUMMYPROOF")
      response.successful?.should be false
    end
  end

end
