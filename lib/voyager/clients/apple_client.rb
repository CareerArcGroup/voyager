# frozen_string_literal: true

module Voyager
  class AppleClient < OAuth2Client
    def initialize(options = {})

      options[:path_prefix]   ||= "/api/v1/companies/#{options[:company_id]}"
      options[:site]          ||= 'https://api-qualification.businessconnect.apple.com/'
      options[:token_url] ||= "https://api-qualification.businessconnect.apple.com/api/v1/oauth2/token"

      super(options)
    end

    def company_id
      options[:company_id]
    end

    def create_business(params = {})
      ensure_token do
        post("/businesses", params)
      end
    end

    def update_business(business_id, params = {})
      ensure_token do
        put("/businesses/#{business_id}", params)
      end
    end

    def business(business_id)
      ensure_token do
        get("/businesses/#{business_id}")
      end
    end

    def businesses
      ensure_token do
        get("/businesses")
      end
    end

    def delete_business(business_id)
      ensure_token do
        delete("/businesses/#{business_id}")
      end
    end

    def create_location(params = {})
      ensure_token do
        post("/locations", params)
      end
    end

    def location(location_id)
      ensure_token do
        get("/locations/#{location_id}")
      end
    end

    def locations
      ensure_token do
        get("/locations")
      end
    end

    def update_location(location_id, etag, params = {})
      headers = { 'if-match' =>  etag }

      ensure_token do
        put("/locations/#{location_id}", params, headers)
      end
    end

    def delete_location(location_id, etag)
      headers = { 'if-match' =>  etag }

      ensure_token do
        delete("/locations/#{location_id}", {}, headers)
      end
    end

    def feedback(resource_type, resource_id)
      ensure_token do
        get("/feedback?ql=resourceType==#{resource_type};resourceId==#{resource_id}")
      end
    end

    def add_standard_headers(headers={})
      additional_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
      }

      super(additional_headers.merge(headers))
    end

    def token_options
      {
        client_id: options[:client_id],
        client_secret: options[:client_secret],
        grant_type: 'client_credentials',
        scope: 'business_connect'
      }
    end

    def transform_body(body)
      body.to_json
    end

    def response_parser
      Voyager::JsonParser
    end

    def get_token
      result = post(options[:token_url], token_options)

      @token = nil
      @access_token = nil

      options[:expires_in] = result['expires_in']
      options[:token] = result['access_token']
    end

    def ensure_token
      get_token if token.blank? || access_token.expired?

      yield
    end
  end
end
