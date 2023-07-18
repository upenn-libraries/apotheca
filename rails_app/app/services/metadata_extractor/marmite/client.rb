# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    # Marmite is a separate application used for creating/retrieving descriptive/structural metadata, and other variant
    # expressions of metadata for objects with information at separate sources. This class creates a client that allows
    # requests to Marmite
    class Client
      class Error < StandardError; end

      attr_reader :url

      def initialize(url:)
        @url = url
      end

      # Fetches MARC XML from Marmite. Raises error if cannot retrieve MARC XML.
      #
      # @param [String] bibnumber
      # @return [String] contain MARC XML for the given bibnumber
      def marc21(bibnumber)
        # Get updated MARC record
        response = Faraday.get(url_for("/api/v2/records/#{bibnumber}/marc21?update=always"))

        return response.body if response.success?

        error = response.status == 500 ? response.body : JSON.parse(response.body)['errors'].join(' ')
        raise Error, "Could not retrieve MARC for #{bibnumber}. Error: #{error}"
      end

      private

      # Combines host and path to create a a full URL.
      def url_for(path)
        uri = URI.parse(url)
        uri = uri.merge(path)
        uri.to_s
      rescue URI::Error => e
        raise Error, "Error generating valid Marmite url: #{e.message}"
      end
    end
  end
end
