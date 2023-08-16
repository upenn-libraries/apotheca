# frozen_string_literal: true

module ImportService
  # Object containing the file location, metadata and structure for a set of assets
  class ColendaMetadata
    VALID_FIELDS = %i[
      item_type abstract call_number collection contributor corporate_name coverage creator date description format
      geographic_subject identifier includes language notes personal_name provenance publisher relation rights source
      subject title
    ].freeze

    attr_reader :errors, :original_metadata

    def initialize(metadata)
      @original_metadata = metadata.deep_symbolize_keys
      @errors = []
    end

    def valid?
      @errors = [] # Clear out previously generated errors.

      @errors << 'invalid metadata fields provided' unless original_metadata.all? { |k,_v| VALID_FIELDS.include?(k) }
      @errors << 'title is required if a bibnumber is not provided' if original_metadata[:title].blank? && original_metadata[:bibnumber].blank?

      errors.empty?
    end

    def invalid?
      !valid?
    end

    def to_apotheca_metadata
      metadata = @original_metadata.deep_dup

      metadata.delete(:includes)

      metadata[:physical_location] = metadata.delete(:call_number)
      metadata[:extent] = metadata.delete(:format)
      metadata[:note] = metadata.delete(:note)
      metadata[:physical_format] = metadata.delete(:item_type)

      metadata[:description] ||= []
      metadata[:description] += metadata.delete(:abstract) || []

      # All names get merged into `name`
      metadata[:name] = []
      metadata[:name] += metadata.delete(:personal_name) || []
      metadata[:name] += metadata.delete(:corporate_names) || []
      metadata[:name] += (metadata.delete(:contributor) || []).map do |n|
        {
          value: n,
          role: [{ value: 'Contributor', uri: 'https://id.loc.gov/vocabulary/relators/ctb' }]
        }
      end
      metadata[:name] += (metadata.delete(:creator) || []).map do |n|
        {
          value: n,
          role: [{ value: 'Creator', uri: 'https://id.loc.gov/vocabulary/relators/cre' }]
        }
      end

      # First title goes to `title`, rest of titles go to `alt_title`.
      if (titles = metadata.delete(:title))
        metadata[:title] = [titles[0]]
        metadata[:alt_title] = titles[1..]
      end

      # Moving rights URIs into `rights` and moving any textual rights to `rights_note`.
      # TODO: URIs need to be moved to URI fields, need to have a map of URI to value
      rights_uris = metadata.fetch(:rights, [])
                            .select { |r| r.match(/\Ahttps?:\/\/(rightsstatements|creativecommons)\.org\S+\Z/) }
      metadata[:rights_note] = metadata.fetch(:rights, []) - rights_uris
      metadata[:rights] = rights_uris # TODO: probably need a map from uri to value...

      # Add uri to languages
      metadata[:language] = metadata.fetch(:language, []).map do |l|
        if (language = ISO_639.find_by_english_name(l))
          { value: language.english_name, uri: "https://id.loc.gov/vocabulary/iso639-2/#{language.alpha3}" }
        else
          { value: l }
        end
      end

      metadata.compact_blank!
      metadata.transform_values { |values| values.map { |v| v.is_a?(Hash) ? v : { value: v } } }
    end
  end
end
