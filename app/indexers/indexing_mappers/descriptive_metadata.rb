# frozen_string_literal: true

module IndexingMappers
  # Mapping from source data to Solr fields
  # Methods here should be names after values in the ItemResource::DescriptiveMetadata::FIELDS array,
  # and return a hash that will be used to construct the JSON data sent to Solr to index a Resource.
  # While much of this looks repetitive, it leaves open each field for quick and easy customization,
  # while making indexed fields very explicit.
  class DescriptiveMetadata
    attr_reader :data

    # @param [Hash] data
    def initialize(data:)
      @data = data
    end

    # @return [Hash{Symbol->Unknown}]
    def alt_title
      { alt_title_tsim: data[:alt_title].pluck(:value),
        alt_title_tesim: data[:alt_title].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def bibnumber
      { bibnumber_ss: data.dig(:bibnumber, 0, :value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def collection
      { collection_tsim: data[:collection].pluck(:value),
        collection_tesim: data[:collection].pluck(:value),
        collection_ssim: data[:collection].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def coverage
      { coverage_tsim: data[:coverage].pluck(:value),
        coverage_tesim: data[:coverage].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def date
      { date_tsim: data[:date].pluck(:value),
        date_tesim: data[:date].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def description
      { description_tsim: data[:description].pluck(:value),
        description_tesim: data[:description].pluck(:value) }
    end

    def extent
      { extent_tsim: data[:extent].pluck(:value),
        extent_tesim: data[:extent].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def geographic_subject
      { geographic_subject_tsim: data[:geographic_subject].pluck(:value),
        geographic_subject_tesim: data[:geographic_subject].pluck(:value),
        geographic_subject_ssim: data[:geographic_subject].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def identifier
      { identifier_ssim: data[:identifier].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def item_type
      { item_type_ssim: data[:item_type].pluck(:value),
        item_type_ssi: data.dig(:item_type, 0, :value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def language
      { language_ssim: data[:language].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def location
      { location_tsim: data[:location].pluck(:value),
        location_tesim: data[:location].pluck(:value),
        location_ssim: data[:location].pluck(:value) }
    end

    # TODO: Should roles be indexed?
    # @return [Hash{Symbol->Unknown}]
    def name
      { name_tsim: data[:name].pluck(:value),
        name_tesim: data[:name].pluck(:value),
        name_ssim: data[:name].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def note
      { note_tsim: data[:note].pluck(:value),
        note_tesim: data[:note].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def physical_format
      { physical_format_ssim: data[:physical_format].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def physical_location
      { physical_location_tsim: data[:physical_location].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def provenance
      { provenance_tsim: data[:provenance].pluck(:value),
        provenance_tesim: data[:provenance].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def publisher
      { publisher_tsim: data[:publisher].pluck(:value),
        publisher_tesim: data[:publisher].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def relation
      { relation_tsim: data[:relation].pluck(:value),
        relation_tesim: data[:relation].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def rights
      { rights_tsim: data[:rights].pluck(:value),
        rights_tesim: data[:rights].pluck(:value) }
    end

    def rights_note
      { rights_note_tsim: data[:rights_note].pluck(:value),
        rights_note_tesim: data[:rights_note].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def subject
      { subject_tsim: data[:subject].pluck(:value),
        subject_tesim: data[:subject].pluck(:value),
        subject_ssim: data[:subject].pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def title
      { title_tsim: data[:title].pluck(:value),
        title_ssim: data[:title].pluck(:value),
        title_tesim: data[:title].pluck(:value),
        title_tsi: data.dig(:title, 0, :value),
        title_ssi: data.dig(:title, 0, :value),
        title_tesi: data.dig(:title, 0, :value) }
    end
  end
end
