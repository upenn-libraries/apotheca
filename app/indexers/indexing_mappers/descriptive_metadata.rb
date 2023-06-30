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
      { alt_title_tsim: data[:alt_title],
        alt_title_tesim: data[:alt_title] }
    end

    # @return [Hash{Symbol->Unknown}]
    def bibnumber
      { bibnumber_ss: data[:bibnumber].first }
    end

    # @return [Hash{Symbol->Unknown}]
    def collection
      { collection_tsim: data[:collection],
        collection_tesim: data[:collection],
        collection_ssim: data[:collection] }
    end

    # @return [Hash{Symbol->Unknown}]
    def coverage
      { coverage_tsim: data[:coverage],
        coverage_tesim: data[:coverage] }
    end

    # @return [Hash{Symbol->Unknown}]
    def date
      { date_tsim: data[:creator],
        date_tesim: data[:creator] }
    end

    # @return [Hash{Symbol->Unknown}]
    def description
      { description_tsim: data[:description],
        description_tesim: data[:description] }
    end

    def extent
      { extent_tsim: data[:extent],
        extent_tesim: data[:extent] }
    end

    # @return [Hash{Symbol->Unknown}]
    def geographic_subject
      { geographic_subject_tsim: data[:geographic_subject].pluck(:label),
        geographic_subject_tesim: data[:geographic_subject].pluck(:label),
        geographic_subject_ssim: data[:geographic_subject].pluck(:label) }
    end

    # @return [Hash{Symbol->Unknown}]
    def identifier
      { identifier_ssim: data[:identifier] }
    end

    # @return [Hash{Symbol->Unknown}]
    def item_type
      { item_type_ssim: data[:item_type].pluck(:label),
        item_type_ssi: data.dig(:item_type, 0, :label) }
    end

    # @return [Hash{Symbol->Unknown}]
    def language
      { language_ssim: data[:language].pluck(:label) }
    end

    # @return [Hash{Symbol->Unknown}]
    def location
      { location_tsim: data[:location].pluck(:label),
        location_tesim: data[:location].pluck(:label),
        location_ssim: data[:location].pluck(:label) }
    end

    # TODO: Should roles be indexed?
    # @return [Hash{Symbol->Unknown}]
    def name
      { name_tsim: data[:name].pluck(:label),
        name_tesim: data[:name].pluck(:label),
        name_ssim: data[:name].pluck(:label) }
    end

    # @return [Hash{Symbol->Unknown}]
    def note
      { note_tsim: data[:note],
        note_tesim: data[:note] }
    end

    # @return [Hash{Symbol->Unknown}]
    def physical_format
      { physical_format_ssim: data[:physical_format].pluck(:label) }
    end

    # @return [Hash{Symbol->Unknown}]
    def physical_location
      { call_number_tsim: data[:call_number] }
    end

    # @return [Hash{Symbol->Unknown}]
    def provenance
      { provenance_tsim: data[:provenance],
        provenance_tesim: data[:provenance] }
    end

    # @return [Hash{Symbol->Unknown}]
    def publisher
      { publisher_tsim: data[:publisher],
        publisher_tesim: data[:publisher] }
    end

    # @return [Hash{Symbol->Unknown}]
    def relation
      { relation_tsim: data[:relation],
        relation_tesim: data[:relation] }
    end

    # @return [Hash{Symbol->Unknown}]
    def rights
      { rights_tsim: data[:rights].pluck(:label),
        rights_tesim: data[:rights].pluck(:label) }
    end

    def rights_note
      { rights_note_tsim: data[:rights_note],
        rights_note_tesim: data[:rights_note] }
    end

    # @return [Hash{Symbol->Unknown}]
    def subject
      { subject_tsim: data[:subject].pluck(:label),
        subject_tesim: data[:subject].pluck(:label),
        subject_ssim: data[:subject].pluck(:label) }
    end

    # @return [Hash{Symbol->Unknown}]
    def title
      { title_tsim: data[:title],
        title_ssim: data[:title],
        title_tesim: data[:title],
        title_tsi: data[:title].first,
        title_ssi: data[:title].first,
        title_tesi: data[:title].first }
    end
  end
end
