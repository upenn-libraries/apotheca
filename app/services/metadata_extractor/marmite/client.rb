module MetadataExtractor
  class Marmite
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

        error = JSON.parse(response.body)['errors'].join(' ')
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
