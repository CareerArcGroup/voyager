
require 'oauth'
require 'json'
require 'logger'
require 'voyager/version'
require 'voyager/mime'
require 'voyager/util'
require 'voyager/trace'

require 'voyager/logging/http_logger'
require 'voyager/logging/gelf_formatter'

require 'voyager/client'
require 'voyager/clients/oauth_client'
require 'voyager/clients/oauth2_client'
require 'voyager/clients/twitter_client'
require 'voyager/clients/twitter_ads_client'
require 'voyager/clients/twitter_enterprise_client'
require 'voyager/clients/linked_in_client'
require 'voyager/clients/facebook_client'
require 'voyager/clients/slack_client'
require 'voyager/clients/bitly_client'
require 'voyager/clients/microsoft_graph_client'

require 'voyager/parser'
require 'voyager/parsers/json_parser'
require 'voyager/parsers/twitter_parser'
require 'voyager/parsers/linked_in_parser'
require 'voyager/parsers/facebook_parser'
require 'voyager/parsers/slack_parser'
require 'voyager/parsers/twitter_enterprise_parser'
require 'voyager/parsers/bitly_parser'

module Voyager
  extend self

  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def trace?
    @trace
  end

  def trace!
    @trace = true
  end
end
