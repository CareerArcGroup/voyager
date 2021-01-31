# frozen_string_literal: true

module Voyager
  class MicrosoftGraphClient < OAuth2Client
    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options = {})
      options[:site]          ||= 'https://graph.microsoft.com'
      options[:authorize_url] ||= 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
      options[:token_url]     ||= 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
      options[:path_prefix]   ||= '/v1.0'

      super(options)
    end

    def authorize_url(redirect_uri, options = {})
      super(redirect_uri, options.merge(scope: options[:scope].join(' ')))
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # get general information about the user. optionally pass in an array
    # of specific fields to get a refined list of information...
    def account_info(*fields)
      get('/me', select: fields)
    end

    # ============================================================================
    # Files
    # ============================================================================

    def drives
      get('/me/drives')
    end

    def drive
      get('/me/drive')
    end

    def drive_items(item_id = 'root', options = {})
      get("/me/drive/#{item_id}/children", options)
    end

    protected

    def get(path, params = {})
      super(path + build_query(params))
    end

    def build_query(query)
      return '' if query.nil? || query.empty?

      query_string = query.map { |key, value| "$#{key}=#{build_query_value(value)}" }
      "?#{query_string.join('&')}"
    end

    def build_query_value(value)
      value.is_a?(Array) ? value.join(',') : value.to_s
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      Voyager::JsonParser
    end
  end
end
