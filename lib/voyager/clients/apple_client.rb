# frozen_string_literal: true

module Voyager
  class AppleClient < OAuth2Client
    def initialize(options = {})
      options[:api_version]   ||= 'v3'
      options[:path_prefix]   ||= "/api/#{options[:api_version]}/companies/#{options[:company_id]}"
      options[:site]          ||= 'https://data-qualification.businessconnect.apple.com/'
      options[:token_url]     ||= "#{options[:site]}api/#{options[:api_version]}/oauth2/token"

      super(options)
    end

    def company_id
      options[:company_id]
    end

    def create_brand(params = {})
      ensure_token if ensure_token?

      post('/brands', params)
    end

    def update_brand(brand_id, params = {})
      ensure_token if ensure_token?

      put("/brands/#{brand_id}", params)
    end

    def brand(brand_id)
      ensure_token if ensure_token?

      get("/brands/#{brand_id}")
    end

    def brands
      ensure_token if ensure_token?

      get('/brands')
    end

    def delete_brand(brand_id)
      ensure_token if ensure_token?

      delete("/brands/#{brand_id}")
    end

    def create_location(params = {})
      ensure_token if ensure_token?

      post('/locations', params)
    end

    def location(location_id)
      ensure_token if ensure_token?

      get("/locations/#{location_id}")
    end

    def locations
      ensure_token if ensure_token?

      get('/locations')
    end

    def update_location(location_id, etag, params = {})
      ensure_token if ensure_token?
      headers = { 'if-match' => etag }

      put("/locations/#{location_id}", params, headers)
    end

    def delete_location(location_id, etag)
      ensure_token if ensure_token?
      headers = { 'if-match' => etag }

      delete("/locations/#{location_id}", {}, headers)
    end

    def feedback(resource_type, resource_id)
      ensure_token if ensure_token?

      get("/feedback?ql=resourceType==#{resource_type};resourceId==#{resource_id}")
    end

    def add_standard_headers(headers = {})
      additional_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
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

    def retrieve_token
      result = post(options[:token_url], token_options)

      @token = nil
      @access_token = nil

      options[:expires_in] = result['expires_in']
      options[:token] = result['access_token']
    end

    def ensure_token
      retrieve_token if token.blank? || access_token.expired?
    end

    def ensure_token?
      options[:ensure_token]
    end
  end
end
