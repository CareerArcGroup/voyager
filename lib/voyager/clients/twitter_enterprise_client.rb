# frozen_string_literal: true

module Voyager
  class TwitterEnterpriseClient < OAuthClient
    # ========================================================================
    # Client Initializers and Public Methods
    # ========================================================================

    def initialize(options = {})
      options[:site] ||= 'https://data-api.twitter.com'
      options[:path_prefix] ||= ''

      super(options)
    end

    def totals(options = {})
      params = default_totals_options.merge(options)
      post('/insights/engagement/totals', params.to_json)
    end

    def recent_engagement(options = {})
      params = default_historical_options.merge(options)
      post('/insights/engagement/28hr', params.to_json)
    end

    def historical_engagement(options = {})
      params = default_historical_options.merge(options)
      post('/insights/engagement/historical', params.to_json)
    end

    def default_totals_options
      {
        engagement_types: %w[impressions engagements favorites retweets],
        groupings: {
          by_tweet_by_type: {
            group_by: %w[tweet.id engagement.type]
          }
        }
      }
    end

    def default_historical_options
      {
        engagement_types: %w[impressions engagements favorites retweets replies video_views media_views media_engagements url_clicks hashtag_clicks detail_expands permalink_clicks email_tweet user_follows user_profile_clicks],
        groupings: {
          hourly_by_tweet_and_type: {
            group_by: %w[tweet.id engagement.type engagement.day engagement.hour]
          }
        }
      }
    end

    protected

    def add_standard_headers(headers = {})
      super(headers.merge(
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      ))
    end

    def response_parser
      Voyager::TwitterEnterpriseParser
    end
  end
end
