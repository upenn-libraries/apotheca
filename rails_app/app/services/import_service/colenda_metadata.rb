# frozen_string_literal: true

module ImportService
  # Object containing the file location, metadata and structure for a set of assets
  class ColendaMetadata
    VALID_FIELDS = %i[
      item_type abstract call_number collection contributor corporate_name coverage creator date description format
      geographic_subject identifier includes language notes personal_name provenance publisher relation rights source
      subject title bibnumber type call_no
    ].freeze

    RIGHTS_URI_TO_VALUE = {
      'rightsstatements.org/vocab/NoC-US/1.0' => 'No Copyright - United States',
      'rightsstatements.org/vocab/InC/1.0' => 'In Copyright',
      'rightsstatements.org/vocab/CNE/1.0' => 'Copyright Not Evaluated',
      'rightsstatements.org/vocab/UND/1.0' => 'Copyright Undetermined',
      'creativecommons.org/publicdomain/zero/1.0' => 'CC0 1.0 Universal',
      'creativecommons.org/licenses/by-nc-sa/3.0' => 'Attribution-NonCommercial-ShareAlike 3.0 Unported',
      'creativecommons.org/licenses/by-nc/4.0' => 'Attribution-NonCommercial 4.0 International',
      'creativecommons.org/publicdomain/mark/1.0' => 'Public Domain Mark 1.0'
    }.freeze

    attr_reader :errors, :original_metadata

    def initialize(metadata)
      @original_metadata = metadata
      @errors = []
    end

    def valid?
      @errors = [] # Clear out previously generated errors.

      @errors << 'invalid metadata fields provided' unless original_metadata.all? { |k, _v| VALID_FIELDS.include?(k) }
      @errors << 'title is required if a bibnumber is not provided' if original_metadata[:title].blank? && original_metadata[:bibnumber].blank?

      errors.empty?
    end

    def invalid?
      !valid?
    end

    def to_apotheca_metadata
      metadata = @original_metadata.deep_dup
      metadata = remove_empty_values(metadata)

      metadata.delete(:includes)
      metadata.delete(:call_no) # duplicate field in some records, should be ignored.

      metadata[:physical_location] = metadata.delete(:call_number)
      metadata[:extent] = metadata.delete(:format)
      metadata[:note] = metadata.delete(:notes)

      metadata[:physical_format] = []
      metadata[:physical_format] += metadata.delete(:item_type) || []
      metadata[:physical_format] += metadata.delete(:type) || []

      metadata[:description] ||= []
      metadata[:description] += metadata.delete(:abstract) || []

      # All names get merged into `name`
      metadata[:name] = []
      metadata[:name] += metadata.delete(:personal_name) || []
      metadata[:name] += metadata.delete(:corporate_name) || []
      metadata[:name] += contributors_to_names(metadata.delete(:contributor))
      metadata[:name] += creators_to_names(metadata.delete(:creator))

      # First title goes to `title`, rest of titles go to `alt_title`.
      if (titles = metadata.delete(:title))
        metadata[:title] = [titles[0]]
        metadata[:alt_title] = titles[1..]
      end

      metadata.merge!(rights_uri_and_note(metadata.delete(:rights)))

      metadata[:language] = languages_with_uris(metadata.delete(:language))

      metadata.compact_blank!
      metadata.transform_values { |values| values.map { |v| v.is_a?(Hash) ? v : { value: v } } }
    end

    private

    def remove_empty_values(hash)
      hash.transform_values(&:compact_blank).compact_blank
    end

    # Contributors from the old metadata schema are migrated to names and a contributor role is added.
    def contributors_to_names(contributors)
      return [] if contributors.blank?

      contributors.map do |n|
        {
          value: n,
          role: [{ value: 'Contributor', uri: 'https://id.loc.gov/vocabulary/relators/ctb' }]
        }
      end
    end

    # Creators from the old metadata schema are migrated to names and a creator role is added.
    def creators_to_names(creators)
      return [] if creators.blank?

      creators.map do |n|
        {
          value: n,
          role: [{ value: 'Creator', uri: 'https://id.loc.gov/vocabulary/relators/cre' }]
        }
      end
    end

    # Adding URIs to languages.
    def languages_with_uris(languages)
      return [] if languages.blank?

      languages.map do |l|
        if (language = ISO_639.find_by_english_name(l))
          { value: language.english_name, uri: "https://id.loc.gov/vocabulary/iso639-2/#{language.alpha3}" }
        else
          { value: l }
        end
      end
    end

    def rights_uri_and_note(rights)
      return {} if rights.blank?

      new_fields = {}

      rights_uris = rights.select { |r| r.match(%r{\Ahttps?://(rightsstatements|creativecommons)\.org\S+\Z}) }

      new_fields[:rights_note] = rights - rights_uris
      new_fields[:rights] = rights_uris.map do |uri|
        uri = normalize_rights_uri(uri)
        value = RIGHTS_URI_TO_VALUE.find { |u, _| uri.match?(%r{https?://#{u}/?}) }[1]
        { value: value, uri: uri }
      end

      new_fields
    end

    def normalize_rights_uri(uri)
      # Remove query_string
      partitions = uri.partition('?')
      uri = partitions[0] || partitions[2]

      # Use correct URI for rightsstatement uri
      uri.gsub!('page', 'vocab') if uri.include?('rightsstatements')

      uri
    end
  end
end
