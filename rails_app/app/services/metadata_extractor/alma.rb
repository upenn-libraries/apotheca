# frozen_string_literal: true

module MetadataExtractor
  # Retrieve MARC XML from Alma and transform it into descriptive metadata
  class Alma
    attr_reader :client

    def initialize(client: Alma::Client.new)
      @client = client
    end

    def descriptive_metadata(bibnumber)
      marc_xml = client.marc_xml(bibnumber)
      MARC::Transformer.new.run(marc_xml)
    end
  end
end
