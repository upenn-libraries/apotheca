# frozen_string_literal: true

module Solr
  module QueryMaps
    module Item
      ROWS_OPTIONS = [20, 50, 100, 250].freeze
      MAX_BULK_EXPORT_ROWS = 100_000

      # Methods for grabbing all mappable values
      class Type
        class << self
          # @return [Array]
          def fields
            self::MAP.keys
          end

          def field_map
            fields.index_by do |field|
              field.to_s.titleize
            end
          end
        end
      end

      class Sort < Type
        MAP = {
          score: :score,
          title: :title_ssi,
          created_at: :created_at_dtsi,
          updated_at: :updated_at_dtsi,
          first_published_at: :first_published_at_dtsi,
          last_published_at: :last_published_at_dtsi
        }.freeze
      end

      class Filter < Type
        MAP = {
          internal_resource: :internal_resource_ssim,
          published: :published_bsi,
          created_by: :created_by_ssi,
          updated_by: :updated_by_ssi,
          collection: :collection_ssim,
          corporate_name: :corporate_name_ssim,
          physical_format: :physical_format_ssim,
          geographic_subject: :geographic_subject_ssim,
          item_type: :item_type_ssim,
          language: :language_ssim,
          names: :name_ssim,
          subject: :subject_ssim
        }.freeze
      end

      class Search < Type
        MAP = {
          alt_title: :alt_title_tsim,
          bibnumber: :bibnumber_ss,
          collection: :collection_tsim,
          coverage: :coverage_tsim,
          date: :date_tsim,
          description: :description_tsim,
          extent: :extent_tsim,
          geographic_subject: :geographic_subject_tsim,
          identifier: :identifier_ssim,
          item_type: :item_type_ssim,
          language: :language_ssim,
          location: :location_tsim,
          name: :name_tsim,
          note: :note_tsim,
          physical_format: :physical_format_ssim,
          physical_location: :physical_format_tsim,
          provenance: :provenance_tsim,
          publisher: :publisher_tsim,
          relation: :relation_tsim,
          rights: :rights_tsim,
          rights_note: :rights_tsim,
          subject: :subject_tsim,
          title: :title_tsim
        }.freeze
      end
    end
  end
end
