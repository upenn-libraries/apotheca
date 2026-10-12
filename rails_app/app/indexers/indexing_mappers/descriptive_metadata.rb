# frozen_string_literal: true

module IndexingMappers
  # Mapping from source data to Solr fields
  # Methods here should be named after values in the ItemResource::DescriptiveMetadata::FIELDS array,
  # and return a hash that will be used to construct the JSON data sent to Solr to index a Resource.
  # While much of this looks repetitive, it leaves open each field for quick and easy customization,
  # while making indexed fields very explicit.
  # Some guidelines for field usage:
  # For a searchable, multivalued text field, use *_tsim
  # For a value that will be used as a facet, use *_ssim (multivalued) or *_ssi (single valued)
  class DescriptiveMetadata
    attr_reader :data

    # @param [Hash] data
    def initialize(data:)
      @data = data
    end

    # @return [Hash{Symbol->Unknown}]
    def alt_title
      { alt_title_tsim: data[:alt_title]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def bibnumber
      { bibnumber_ssi: data.dig(:bibnumber, 0, :value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def collection
      { collection_tsim: data[:collection]&.pluck(:value),
        collection_ssim: data[:collection]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def coverage
      { coverage_tsim: data[:coverage]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def date
      { date_tsim: data[:date]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def description
      { description_tsim: data[:description]&.pluck(:value) }
    end

    def extent
      { extent_tsim: data[:extent]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def geographic_subject
      { geographic_subject_tsim: data[:geographic_subject]&.pluck(:value),
        geographic_subject_ssim: data[:geographic_subject]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def identifier
      { identifier_ssim: data[:identifier]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def item_type
      { item_type_ssim: data[:item_type]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def language
      { language_ssim: data[:language]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def location
      { location_tsim: data[:location]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def name
      name_with_role = data[:name]&.map do |n|
        roles = n[:role]&.pluck(:value)&.join(', ')
        roles = "(#{roles})" if roles.present?

        [n[:value], roles].join(' ')
      end

      all_roles = data[:name]&.pluck(:role)&.flatten&.compact_blank&.pluck(:value)

      { name_tsim: data[:name]&.pluck(:value),
        name_ssim: data[:name]&.pluck(:value),
        name_role_tsim: all_roles,
        name_with_role_ssm: name_with_role }
    end

    # @return [Hash{Symbol->Unknown}]
    def note
      { note_tsim: data[:note]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def physical_format
      { physical_format_ssim: data[:physical_format]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def physical_location
      { physical_location_tsim: data[:physical_location]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def provenance
      { provenance_tsim: data[:provenance]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def publisher
      { publisher_tsim: data[:publisher]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def relation
      { relation_tsim: data[:relation]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def rights
      { rights_tsim: data[:rights]&.pluck(:value) }
    end

    def rights_note
      { rights_note_tsim: data[:rights_note]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def subject
      { subject_tsim: data[:subject]&.pluck(:value),
        subject_ssim: data[:subject]&.pluck(:value) }
    end

    # @return [Hash{Symbol->Unknown}]
    def title
      { title_tsim: data[:title]&.pluck(:value),
        title_ssi: data.dig(:title, 0, :value) }
    end
  end
end
