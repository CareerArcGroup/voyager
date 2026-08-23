require 'spec_helper'
require 'yaml'
include Voyager

LINKEDIN_TEST_COMPANY_ID = 2414183
LINKEDIN_TEST_COMPANY_URN = "urn:li:organization:2414183"

# ID & URN are for profile below
# https://www.linkedin.com/in/careerarc-developers-bba66154/
LINKEDIN_SHARES_PROFILE_ID = 'aL3tXjxVL4'
LINKEDIN_SHARES_PROFILE_URN = 'urn:li:person:aL3tXjxVL4'

register_upload_opts = {
  registerUploadRequest: {
    owner: LINKEDIN_SHARES_PROFILE_URN,
    recipes: ['urn:li:digitalmediaRecipe:feedshare-image'],
    serviceRelationships: [
      {
        identifier: 'urn:li:userGeneratedContent',
        relationshipType: 'GENERIC'
      }
    ],
    supportedUploadMechanism: [
      'SYNCHRONOUS_UPLOAD'
    ]
  }
}



config = SpecHelper::Config.new(Voyager::LinkedInClient)

describe LinkedInClient do

  it "get an OK response from the LinkedIn test endpoint" do
    config.client.should be_connected
  end

  context "with valid LinkedIn credentials" do

    it "is authorized" do
      config.client.should be_authorized
    end

    it "can get user account info" do
      response = config.client.account_info
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it "can get company info" do
      response = config.client.company_info(LINKEDIN_TEST_COMPANY_ID)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it 'can register an upload', skip: 'register_upload is not a method and using image_initializes raises exception: Unpermitted fields present in REQUEST_BODY: Data Processing Exception while processing fields [/registerUploadRequest]' do
      response = config.client.register_upload(register_upload_opts)
      expect(response).to be_successful
      expect(response.dig('value', 'asset')). to match(/urn\:li\:digitalmediaAsset\:\S+/)
    end

    it 'can upload images', skip: 'register_upload is not a method and using image_initializes raises exception: Unpermitted fields present in REQUEST_BODY: Data Processing Exception while processing fields [/registerUploadRequest]' do
      register = config.client.register_upload(register_upload_opts)
      upload_url = register.data.dig('value', 'uploadMechanism', 'com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest', 'uploadUrl')
      source = 'https://www.sciencemag.org/sites/default/files/styles/inline__450w__no_aspect/public/dogs_1280p_0.jpg'

      response = config.client.upload(upload_url, Voyager::Util.upload_from(source))
      expect(response).to be_successful
    end

    it 'can share' do
      response = config.client.share(
        {
          owner: LINKEDIN_SHARES_PROFILE_URN,
          subject: "Test Share Subject",
          text: {
            text: "Hello World from dimension #{Random.rand(9999)+1}"
          }
        }
      )

      expect(response).to be_successful
      expect(response.data['activity']).not_to be_nil
    end

    it "can share with images", skip: 'register_upload is not a method and using image_initializes raises exception: Unpermitted fields present in REQUEST_BODY: Data Processing Exception while processing fields [/registerUploadRequest]' do
      img_url = 'https://post.medicalnewstoday.com/wp-content/uploads/sites/3/2020/02/322868_1100-1100x628.jpg'
      register = config.client.register_upload(register_upload_opts)
      upload_url = register.dig('value', 'uploadMechanism', 'com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest', 'uploadUrl')
      asset_urn = register.dig('value', 'asset')
      config.client.upload(upload_url, Voyager::Util.upload_from(img_url))

      response = config.client.share(
        {
          content: {
            contentEntities: [
              {
                entity: asset_urn
              }
            ],
            title: "Test Share with Content",
            shareMediaCategory: 'IMAGE'
          },
          distribution: {
            "linkedInDistributionTarget": {}
          },
          owner: LINKEDIN_SHARES_PROFILE_URN,
          subject: "Test Share Subject",
          text: {
            text: "Hello World from dimension #{Random.rand(9999)+1}"
          }
        }
      )

      response.successful?.should be true
      response.data["activity"].nil?.should be false
    end

    it 'can get amount of user connections', skip: 'access denied error for LINKEDIN_SHARES_PROFILE_ID' do
      connections = config.client.connection_size(LINKEDIN_SHARES_PROFILE_ID)
      connections.data['firstDegreeSize'] >= 0
    end

    it 'can get share statistics for `shares`' do
      allow(config.client).to receive(:perform_request)

      entity_urn = 'urn:li:organization:1'
      share_urn = 'urn:li:share:2'

      config.client.share_statistics(entity_urn, [share_urn])

      expect(config.client).to have_received(:perform_request).with(
        :get, "/organizationalEntityShareStatistics?q=organizationalEntity&organizationalEntity=#{CGI.escape(entity_urn)}&shares=List(#{CGI.escape(share_urn)})"
      )
    end

    it 'can get share statistics for `ugcPosts`' do
      allow(config.client).to receive(:perform_request)

      entity_urn = 'urn:li:organization:1'
      ugc_post_urn = 'urn:li:ugcPost:2'

      config.client.share_statistics(entity_urn, [ugc_post_urn])

      expect(config.client).to have_received(:perform_request).with(
        :get, "/organizationalEntityShareStatistics?q=organizationalEntity&organizationalEntity=#{CGI.escape(entity_urn)}&ugcPosts=List(#{CGI.escape(ugc_post_urn)})"
      )
    end

    it 'can get share statistics for `shares` and `ugcPosts`' do
      allow(config.client).to receive(:perform_request)

      entity_urn = 'urn:li:organization:1'
      share_urn = 'urn:li:share:2'
      ugc_post_urn = 'urn:li:ugcPost:3'

      config.client.share_statistics(entity_urn, [share_urn, ugc_post_urn])

      expect(config.client).to have_received(:perform_request).with(
        :get, "/organizationalEntityShareStatistics?q=organizationalEntity&organizationalEntity=#{CGI.escape(entity_urn)}&shares=List(#{CGI.escape(share_urn)})&ugcPosts=List(#{CGI.escape(ugc_post_urn)})"
      )
    end

    it 'can refresh the access token' do
      refreshed = config.client.refresh!

      # #refresh! returns nil when no refresh_token is configured, so assert on it
      # to keep a missing credential from passing vacuously...
      expect(refreshed).not_to be_nil
      expect(refreshed.token).not_to be_empty
      expect(config.client.account_info).to be_successful
    end
  end

  context "with invalid LinkedIn credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

end
