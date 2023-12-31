# frozen_string_literal: true

module MetadataExtractor
  # Retrieve MARC XML from Marmite and transform it into descriptive metadata
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
