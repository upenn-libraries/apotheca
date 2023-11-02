# frozen_string_literal: true

class ItemResource
  # Descriptive metadata for Item.
  class DescriptiveMetadata < Valkyrie::Resource
    # Defining descriptive metadata fields for ItemResource.
    module Fields
      TEXT = :text
      TERM = :term
      NAME = :name

      CONFIG = {
        title:              TEXT,
        alt_title:          TEXT,
        name:               NAME,
        publisher:          TEXT,
        date:               TEXT,
        collection:         TEXT,
        item_type:          TERM,
        physical_format:    TERM,
        description:        TEXT,
        extent:             TEXT,
        language:           TERM,
        coverage:           TEXT,
        note:               TEXT,
        relation:           TEXT,
        subject:            TERM,
        geographic_subject: TERM,
        location:           TERM,
        physical_location:  TEXT,
        provenance:         TEXT,
        rights:             TERM,
        rights_note:        TEXT,
        identifier:         TEXT,
        bibnumber:          TEXT
      }.freeze

      def self.all
        CONFIG.keys
      end
    end

    Fields::CONFIG.each do |field, type|
      klass = "#{name}::#{type.to_s.titlecase}Field".constantize
      attribute field, Valkyrie::Types::Array.of(klass)
    end

    def to_json_export
      attributes.slice(*Fields.all)
                .transform_values { |v| v.map(&:to_json_export) }
                .compact_blank
    end
  end
end
