# frozen_string_literal: true

module FileCharacterization
  # Class to interact with FITS service.
  class Fits
    class Error < StandardError; end

    attr_reader :url

    def initialize(url:)
      @url = url
    end

    # Run file characterization on file contents provided.
    #
    # @param contents [String] file contents
    # @param filename [String]
    def examine(contents:, filename:)
      uri = URI.parse("#{url}/examine?includeStandardOutput=false")

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form([['datafile', contents, { filename: filename }]], 'multipart/form-data')

      response = http.request(request)

      raise Error, "Could not successfully characterize contents: #{response.body}" if response.code != '200'

      Metadata.new(response.body)
    end
  end
end
