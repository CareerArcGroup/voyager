# frozen_string_literal: true

module Voyager
  class JsonParser < Parser
    def self.parse_response(response, data, error_key = nil)
      super(response, data)

      if response.raw_data? || data.body.length < 2
        response.data       = data.body
        response.successful = true
      else
        parse_json_data(response, data, error_key)
      end
    end

    def self.parse_json_data(response, data, error_key)
      response.data       = JSON.parse(data.body)
      response.errors     = response.data[error_key] unless error_key.nil?
      response.successful = data.is_a?(Net::HTTPSuccess) && response.errors.nil?
    rescue JSON::ParserError => e
      response.data       = data.body
      response.successful = false
      response.errors     = e
    end
  end
end
