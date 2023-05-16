# frozen_string_literal: true

module MetadataExtractor
  # Marmite is a separate application used for creating/retrieving descriptive/structural metadata, and other variant
  # expressions of metadata for objects with information at separate sources. This class creates a client that allows
  # requests to Marmite
  class Marmite
    attr_reader :client

    def initialize(url:)
      @client = Client.new(url: url)
    end

    def descriptive_metadata(bibnumber)
      marc_xml = client.marc21(bibnumber)
      Transformer.new(marc_xml).to_descriptive_metadata
    end
  end
end
