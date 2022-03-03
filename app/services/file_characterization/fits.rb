# frozen_string_literal: true

module FileCharacterization
  # Wrapper class to interact with FITS service.
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

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form([['datafile', contents, { filename: filename }]], 'multipart/form-data')

      response = http.request(request)

      raise Error, "Could not successfully characterize contents: #{response.body}" if response.code != '200'

      Metadata.new(response.body)
    end

    # Contains metadata returned by FITS and includes helper methods to parse out commonly used fields.
    class Metadata
      attr_reader :raw

      def initialize(output)
        @raw = clean_output(output)
        @xml = Nokogiri::XML.parse(raw)
      end

      def mime_type
        @xml.at_xpath('/xmlns:fits/xmlns:identification/xmlns:identity/@mimetype')&.text
      end

      def size
        @xml.at_xpath('/xmlns:fits/xmlns:fileinfo/xmlns:size')&.text.to_i
      end

      def md5
        @xml.at_xpath('/xmlns:fits/xmlns:fileinfo/xmlns:md5checksum')&.text
      end

      def duration
        @xml.at_xpath('/xmlns:fits/xmlns:metadata/xmlns:audio/xmlns:duration')&.text
      end

      private

      def clean_output(output)
        xml = Nokogiri::XML.parse(output)
        xml.at_xpath('/xmlns:fits/xmlns:fileinfo/xmlns:filepath')&.remove
        xml.at_xpath('/xmlns:fits/xmlns:statistics')&.remove
        xml.to_xml # TODO: make sure this has as least whitespace as possible
      end
    end
  end
end
