# frozen_string_literal: true

module Solr
  module QueryMaps
    module Item
      # map conventional field name to solr field
      module Mapping
        module Sort
          CREATED_AT = :aaa
          UPDATED_AT = :aaa
          TITLE = :title_ssi
          FIRST_PUBLISHED_AT = :aaa
          LAST_PUBLISHED_AT = :aaa
        end

        module Filter
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

        module Search
          # DescriptiveMetadata
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
end
