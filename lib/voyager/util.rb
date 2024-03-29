require 'open-uri'
require 'net/http/post/multipart'

module Voyager
  module Util

    # ===========================================================================
    # Multi-part helper methods
    # ===========================================================================

    # retrieves data from a file or URL and builds
    # an UploadIO object, which can be used as an
    # argument in constructing a multi-part post...
    def self.upload_from(file_or_url, mime_type=nil)
      file_io = URI.open(file_or_url)
      mime_type ||= Voyager::MIME.mime_type_for(file_or_url)

      UploadIO.new(file_io, mime_type)
    end

  end
end
