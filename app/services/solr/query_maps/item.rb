# frozen_string_literal: true

module Solr
  module QueryMaps
    module Item
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
        CREATED_AT = :created_at_dtsi
        UPDATED_AT = :updated_at_dtsi
        TITLE = :title_ssi
        FIRST_PUBLISHED_AT = :first_published_at_dtsi
        LAST_PUBLISHED_AT = :last_published_at_dtsi
        SCORE = :score
      end

      class Filter < Type
        INTERNAL_RESOURCE = :internal_resource_ssim
        PUBLISHED = :published_bsi
        CREATED_BY = :created_by_ssi
        UPDATED_BY = :updated_by_ssi
        COLLECTION = :collection_ssim
        CORPORATE_NAME = :corporate_name_ssim
        FORMAT = :format_ssim
        GEOGRAPHIC_SUBJECT = :geographic_subject_ssim
        ITEM_TYPE = :item_type_ssim
        LANGUAGE = :language_ssim
        PERSONAL_NAME = :personal_name_ssim
        SUBJECT = :subject_ssim
      end

      class Search < Type
        ABSTRACT = :abstract_tsim
        BIBNUMBER = :bibnumber_ss
        CALL_NUMBER = :call_number_tsim
        COLLECTION = :collection_tsim
        CONTRIBUTOR = :contributor_tsim
        CORPORATE_NAME = :corporate_name_tsim
        COVERAGE = :coverage_tsim
        CREATOR = :creator_tsim
        DATE = :date_tsim
        DESCRIPTION = :description_tsim
        FORMAT = :format_ssim
        GEOGRAPHIC_SUBJECT = :geographic_subject_tsim
        IDENTIFIER = :identifier_ssim
        INCLUDES = :includes_tsim
        ITEM_TYPE = :item_type_ssim
        LANGUAGE = :language_ssim
        NOTES = :notes_tsim
        PERSONAL_NAME = :personal_name_tsim
        PROVENANCE = :provenance_tsim
        PUBLISHER = :publisher_tsim
        RELATION = :relation_tsim
        RIGHTS = :rights_tsim
        SOURCE = :source_tsim
        SUBJECT = :subject_tsim
        TITLE = :title_tsim
      end
    end
  end
end
