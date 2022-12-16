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
      options[:api_version] ||= '202211'

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
    # Videos
    # ============================================================================


    def upload_video(action, options={})
      headers = { 'LinkedIn-Version' =>  api_version }

      post("/videos?action=#{action}", options, headers)
    end

    def video_initialize(options={})
      upload_video('initializeUpload', options)
    end

    def video_finalize(options={})
      upload_video('finalizeUpload', options)
    end


    # ============================================================================
    # images
    # ============================================================================

    def upload_image(action, options={})
      headers = { 'LinkedIn-Version' =>  api_version }

      post("/images?action=#{action}", options, headers)
    end

    def image_initialize(options={})
      upload_image('initializeUpload', options)
    end

    def upload(url, file)
      put(url, file)
    end

    def image(image_urn)
      headers = {
        'X-Restli-Protocol-Version' => nil,
        'LinkedIn-Version' => api_version
      }

       get("/images/#{image_urn}", {}, headers)
    end

    def li_post(options={})
      headers = { 'LinkedIn-Version' => api_version }

      post("/posts", options, headers)
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

    def share_statistics(entity_urn, post_urns, start_date = nil, end_date = nil)
      path = "/organizationalEntityShareStatistics?q=organizationalEntity&organizationalEntity=#{CGI.escape(entity_urn)}"

      share_urns, ugc_urns = post_urns.partition { |urn| urn.start_with?('urn:li:share:') }

      if share_urns.any?
        path += "&shares=List(#{share_urns.map { |u| CGI.escape(u) }.join(',')})"
      end

      if ugc_urns.any?
        path += "&ugcPosts=List(#{ugc_urns.map { |u| CGI.escape(u) }.join(',')})"
      end

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

    def connection_size(user_external_id)
      path = CGI.escape("urn:li:person:#{user_external_id}")
      get("/connections/#{path}")
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

    def transform_body(body)
      JSON.unparse(body)
    end

    def response_parser
      Voyager::LinkedInParser
    end

    def api_version
       options[:api_version]
    end
  end
end
