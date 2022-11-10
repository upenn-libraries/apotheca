# frozen_string_literal: true

module IndexingMappers
  # Mapping from source data to Solr fields
  class DescriptiveMetadata
    attr_reader :data

    # @param [Hash] data
    def initialize(data:)
      @data = data
    end

    # @return [Hash{Symbol->Unknown}]
    def abstract
      { abstract_tsim: data[:abstract],
        abstract_tesim: data[:abstract] }
    end

    # @return [Hash{Symbol->Unknown}]
    def bibnumber
      { bibnumber_ss: data[:bibnumber] }
    end

    # @return [Hash{Symbol->Unknown}]
    def call_number
      { call_number_tsim: data[:call_number] }
    end

    # @return [Hash{Symbol->Unknown}]
    def collection
      { collection_tsim: data[:collection],
        collection_tesim: data[:collection],
        collection_ssim: data[:collection] }
    end

    # @return [Hash{Symbol->Unknown}]
    def contributor
      { contributor_tsim: data[:contributor],
        contributor_tesim: data[:contributor] }
    end

    # @return [Hash{Symbol->Unknown}]
    def corporate_name
      { corporate_name_tsim: data[:corporate_name],
        corporate_name_tesim: data[:corporate_name],
        corporate_name_ssim: data[:corporate_name] }
    end

    # @return [Hash{Symbol->Unknown}]
    def coverage
      { coverage_tsim: data[:coverage],
        coverage_tesim: data[:coverage] }
    end

    # @return [Hash{Symbol->Unknown}]
    def creator
      { creator_tsim: data[:creator],
        creator_tesim: data[:creator] }
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

    # TODO: uh oh, see Kernel#format
    # @return [Hash{Symbol->Unknown}]
    def format
      { format_ssim: data[:format] }
    end

    # @return [Hash{Symbol->Unknown}]
    def geographic_subject
      { geographic_subject_tsim: data[:geographic_subject],
        geographic_subject_tesim: data[:geographic_subject],
        geographic_subject_ssim: data[:geographic_subject] }
    end

    # @return [Hash{Symbol->Unknown}]
    def identifier
      { identifier_ssim: data[:identifier] }
    end

    def includes
      { includes_tsim: data[:includes],
        includes_tesim: data[:includes] }
    end

    # @return [Hash{Symbol->Unknown}]
    def item_type
      { item_type_ssim: data[:item_type],
        item_type_ssi: data[:item_type].try(:first) }
    end

    # @return [Hash{Symbol->Unknown}]
    def language
      { language_ssim: data[:language] }
    end

    # @return [Hash{Symbol->Unknown}]
    def notes
      { notes_tsim: data[:notes],
        notes_tesim: data[:notes] }
    end

    # @return [Hash{Symbol->Unknown}]
    def personal_name
      { personal_name_tsim: data[:personal_name],
        personal_name_tesim: data[:personal_name],
        personal_name_ssim: data[:personal_name] }
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
      { rights_tsim: data[:rights],
        rights_tesim: data[:rights] }
    end

    # @return [Hash{Symbol->Unknown}]
    def source
      { source_tsim: data[:source] }
    end

    # @return [Hash{Symbol->Unknown}]
    def subject
      { subject_tsim: data[:subject],
        subject_tesim: data[:subject],
        subject_ssim: data[:subject] }
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
