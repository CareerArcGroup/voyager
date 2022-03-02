module Voyager
  class SlackParser < Parser

    def self.parse_response(response, data)
      super(response, data)

      response.successful = data.is_a?(Net::HTTPOK)
    end
  end
end
