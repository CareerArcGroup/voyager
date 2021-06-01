require 'spec_helper'
require 'yaml'
include Voyager

LINKEDIN_TEST_COMPANY_ID = 2414183
LINKEDIN_TEST_COMPANY_URN = "urn:li:organization:2414183"
LINKEDIN_SHARES_PROFILE_ID = 'eI2ganNkL9'
LINKEDIN_SHARES_PROFILE_URN = 'urn:li:person:eI2ganNkL9'

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

    it "can share" do
      response = config.client.share(
        {
          content: {
            contentEntities: [
              {
                entityLocation: "http://www.google.com"
              }
            ],
            title: "Test Share with Content"
          },
          distribution: {
            "linkedInDistributionTarget": {}
          },
          owner: LINKEDIN_TEST_COMPANY_URN,
          subject: "Test Share Subject",
          text: {
            text: "Hello World from dimension #{Random.rand(9999)+1}"
          }
        }
      )

      response.successful?.should be true
      response.data["activity"].nil?.should be false
    end


    it "can get company info" do
      response = config.client.company_info(LINKEDIN_TEST_COMPANY_ID)
      response.successful?.should be true
      response.data["id"].nil?.should be false
    end

    it 'can register an upload' do
      response = config.client.register_upload(register_upload_opts)
      expect(response).to be_successful
      expect(response.dig('value', 'asset')). to match(/urn\:li\:digitalmediaAsset\:\S+/)
    end

    it 'can upload images' do
      register = config.client.register_upload(register_upload_opts)
      upload_url = register.data.dig('value', 'uploadMechanism', 'com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest', 'uploadUrl')
      source = 'https://www.sciencemag.org/sites/default/files/styles/inline__450w__no_aspect/public/dogs_1280p_0.jpg'

      response = config.client.upload(upload_url, source: source)
      expect(response.raw_response).to match(/^HTTP\S+\s2[0-9]{2}/)
    end
  end

  context "with invalid LinkedIn credentials" do
    it "is not authorized" do
      config.unauthorized_client.should_not be_authorized
    end
  end

end
