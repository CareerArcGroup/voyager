module Voyager
  class LinkedInClient < OAuth2Client

    # ============================================================================
    # Client Initializers and Public Methods
    # ============================================================================

    def initialize(options={})
      options[:site] ||= 'https://api.linkedin.com'
      options[:authorize_url] ||= 'https://www.linkedin.com/oauth/v2/authorization'
      options[:token_url]     ||= 'https://www.linkedin.com/oauth/v2/accessToken'
      options[:path_prefix] ||= '/v2'

      super(options)
    end

    def authorize_url(redirect_uri, options={})
      super(redirect_uri, options.merge(scope: options[:scope].join(' ')))
    end

    def connected?
      authorized?
    end

    def authorized?
      account_info.successful?
    end

    # ============================================================================
    # Status Methods - These act on Shares
    # ============================================================================

    # for request shape see:
    # https://docs.microsoft.com/en-us/linkedin/marketing/integrations/community-management/shares/share-api#post-shares

    def share(options={})
      post("/shares", options)
    end

    # ============================================================================
    # Assets - for sharing multi-image posts
    # ============================================================================

    def register_upload(options={})
      post("/assets?action=registerUpload", options)
    end

    def upload_status(asset_id)
      get("/assets/#{asset_id}")
    end

    def upload(url, opts={})
      # TODO: figure out how to use standard Net::HTTP request to do this.
      # Known issue: Documentation recommends PUT request, but API responds
      # to PUT reqeusts saying they're not allowed.
      resp = %x{
        curl -iv --upload-file \
          \"#{Voyager::Util.upload_from(opts[:source]).local_path}\" \
          \"#{URI(url)}\" \
          -H "Authorization: Bearer #{token}" \
          -H 'X-Restli-Protocol-Version: 2.0.0'
      }

      Voyager::Response.new(opts[:id], resp, response_parser)
    end

    # ============================================================================
    # Account Methods - These act on the API account
    # ============================================================================

    # get general information about the user. optionally pass in an array
    # of specific fields to get a refined list of information...
    def account_info(*fields)
      get("/me#{field_selector(fields)}")
    end

    # get the list of companies of which the user is an administrator...
    def admin_for_companies
      get("/organizationalEntityAcls?q=roleAssignee&role=ADMINISTRATOR&state=APPROVED&count=100")
    end

    # get general information about a company. optionally pass in an array
    # of specific fields to get a refined list of information...
    def company_info(company_id, *fields)
      get("/organizations/#{company_id}#{field_selector(fields)}")
    end

    def social_actions(activity_urn)
      get("/socialActions/#{CGI.escape(activity_urn)}")
    end

    def social_metadata(activity_urns)
      path = "/socialMetadata"
      get(path, ids: "List(#{activity_urns.join(',')})")
    end

    def shares(owner_urn, options = {})
      sort_by = options.fetch(:sort_by, 'LAST_MODIFIED')
      count = options.fetch(:count, 100)

      # for some reason this endpoint can't be called with
      # 'X-Restli-Protocol-Version' => 2.0.0
      headers = { 'X-Restli-Protocol-Version' => nil }

      path = "/shares?q=owners&owners=#{owner_urn}&sortBy=#{sort_by}&sharesPerOwner=#{count}"
      get(path, {}, headers)
    end

    def follower_counts(entity_urn, start_date=nil, end_date = nil)
      path = "/organizationalEntityFollowerStatistics?q=organizationalEntity&organizationalEntity=#{CGI.escape(entity_urn)}"

      if start_date && end_date
        # milliseconds since epoch
        formatted_start = start_date.to_datetime.strftime('%Q')
        formatted_end = end_date.to_datetime.strftime('%Q')

        path = "#{path}&timeIntervals=(timeRange:(start:#{formatted_start},end:#{formatted_end}),timeGranularityType:DAY)"
      end

      # calling this directly because we need to not encode the : inside of parentheses
      # but inside of URNs, we do need to encode :. We are encoding inside of this method
      # and bypassing generic encoding, but should update to find a generic way to do this.
      perform_request(:get, path)
    end

    def network_size(entity_urn)
      path = "/networkSizes/#{CGI.escape(entity_urn)}?edgeType=CompanyFollowedByMember"
      get(path)
    end

    protected

    def uri_with_query(url, query={})
      uri = super
      # LinkedIn with X-Restli-Protocol-Version 2.0.0 requires these characters
      # to be unescaped
      uri.gsub('%28', '(').gsub('%29', ')').gsub('%2C', ',')
    end

    def field_selector(fields)
      (fields != nil && fields.any?) ? "?projection=(#{fields.join(',')})" : ''
    end

    def add_standard_headers(headers={})
      additional_headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-Restli-Protocol-Version' => '2.0.0'
      }

      super(additional_headers.merge(headers))
    end

    # override Client method; some PUT endpoints require inclusion of query
    # string, Client drops this, using request.api.path instead.
    # Opportunity for refactor to separate out request types, minimize
    # necessary overrides.
    def build_request(request)
      http_request = case request.method
        when :get
          Net::HTTP::Get.new(request.uri.request_uri)
        when :post
          multipart?(request.body) ?
            Net::HTTP::Post::Multipart.new(request.uri.path, to_multipart_params(request.body)) :
            Net::HTTP::Post.new(request.uri).tap do |req|
              req['Content-Type'] ||= (request.headers['Content-Type'] || 'application/x-www-form-urlencoded')
              req.body = transform_body(request.body)
            end
        else
          raise ArgumentError, "Unsupported method '#{request.method}'"
        end

      request.headers.each { |key,value| http_request[key] = value }
      access_token.headers.each { |key, value| http_request[key] = value }
      http_request
    end

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      Voyager::LinkedInParser
    end

  end
end
