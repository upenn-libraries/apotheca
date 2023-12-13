# frozen_string_literal: true

module Solr
  module QueryMaps
    module Item
      ROWS_OPTIONS = [20, 50, 100, 250].freeze
      MAX_BULK_EXPORT_ROWS = 100_000

      # accessor for constant values
      class Type
        class << self
          def method_missing(name)
            raise NoMethodError unless respond_to_missing? name

            const_get name.upcase.to_sym
          end

          def respond_to_missing?(name)
            name.to_sym.in? fields
          end

          # @return [Array]
          def fields
            constants.map do |c|
              c.downcase.to_sym
            end
          end

          def field_map
            fields.index_by do |field|
              field.to_s.titleize
            end
          end
        end
      end

      class Sort < Type
        SCORE = :score
        TITLE = :title_ssi
        CREATED_AT = :created_at_dtsi
        UPDATED_AT = :updated_at_dtsi
        FIRST_PUBLISHED_AT = :first_published_at_dtsi
        LAST_PUBLISHED_AT = :last_published_at_dtsi
      end

      class Filter < Type
        INTERNAL_RESOURCE = :internal_resource_ssim
        PUBLISHED = :published_bsi
        CREATED_BY = :created_by_ssi
        UPDATED_BY = :updated_by_ssi
        COLLECTION = :collection_ssim
        CORPORATE_NAME = :corporate_name_ssim
        PHYSICAL_FORMAT = :physical_format_ssim
        GEOGRAPHIC_SUBJECT = :geographic_subject_ssim
        ITEM_TYPE = :item_type_ssim
        LANGUAGE = :language_ssim
        NAMES = :name_ssim
        SUBJECT = :subject_ssim
      end

      class Search < Type
        ALT_TITLE = :alt_title_tsim
        BIBNUMBER = :bibnumber_ss
        COLLECTION = :collection_tsim
        COVERAGE = :coverage_tsim
        DATE = :date_tsim
        DESCRIPTION = :description_tsim
        EXTENT = :extent_tsim
        GEOGRAPHIC_SUBJECT = :geographic_subject_tsim
        IDENTIFIER = :identifier_ssim
        ITEM_TYPE = :item_type_ssim
        LANGUAGE = :language_ssim
        LOCATION = :location_tsim
        NAMES = :name_tsim
        NOTE = :note_tsim
        PHYSICAL_FORMAT = :physical_format_ssim
        PHYSICAL_LOCATION = :physical_format_tsim
        PROVENANCE = :provenance_tsim
        PUBLISHER = :publisher_tsim
        RELATION = :relation_tsim
        RIGHTS = :rights_tsim
        RIGHTS_NOTE = :rights_tsim
        SUBJECT = :subject_tsim
        TITLE = :title_tsim
      end
    end
  end
end
