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

        raise Error, "Could not retrieve MARC for #{bibnumber}. Error: #{response.body}" unless response.success?

        response.body
      end


    # def self.config
    #   url = Settings&.marmite&.url
    #   raise MissingConfiguration, 'Missing Marmite URL' unless url
    #   { 'url' => url }
    # end

      private

      # Combines host and path to create a a full URL.
      def url_for(path)
        uri = Addressable::URI.parse(url)
        uri.path = path
        uri.to_s
      end
    end
  end
end
