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

    def authorize_url(redirect_uri, addl_configs = {})
      scope = addl_configs.delete(:scope) || options[:scope]
      auth_options = options.merge(scope: scope.join(' ')).merge(addl_configs)
      super(redirect_uri, auth_options)
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

    def search(options = {})
      post('/search/query', options[:body], options[:headers])
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

    def my_drive_items(item_id = 'root', options = {})
      get("/me/drive/#{item_id}/children", options)
    end

    def drive_children(drive_ids)
      drive_ids.map do |drive_id|
        get("/drives/#{drive_id}/root/children")
      end
    end

    def drive_item(drive_id = '/me/drives', item_id = '', options = {})
      get("/drives/#{drive_id}/items/#{item_id}#{options[:expansions]}")
    end

    # ============================================================================
    # Sites
    # ============================================================================

    def site_root
      get('/sites/root')
    end

    def sub_sites(site_id)
      get("/sites/#{site_id}/sites")
    end

    def followed_sites
      get('/me/followedSites')
    end

    def site_drives(site_ids)
      site_ids.map do |site_id|
        get("/sites/#{site_id}/drives")
      end
    end

    protected

    def add_standard_headers(headers = {})
      additional_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
      }

      super(additional_headers.merge(headers))
    end

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
