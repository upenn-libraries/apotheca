# frozen_string_literal: true

class ItemResource
  # Descriptive metadata for Item.
  class DescriptiveMetadata < Valkyrie::Resource
    module Fields
      TEXT = :text
      TERM = :term
      NAME = :name

      CONFIG = {
        title:              TEXT,
        alt_title:          TEXT,
        description:        TEXT,
        name:               NAME,
        collection:         TEXT,
        coverage:           TEXT,
        date:               TEXT,
        extent:             TEXT,
        identifier:         TEXT,
        note:               TEXT,
        physical_location:  TEXT,
        provenance:         TEXT,
        publisher:          TEXT,
        relation:           TEXT,
        physical_format:    TERM,
        item_type:          TERM,
        subject:            TERM,
        geographic_subject: TERM,
        language:           TERM,
        location:           TERM,
        rights:             TERM,
        rights_note:        TEXT,
        bibnumber:          TEXT
      }.freeze

      # Free text descriptive metadata fields
      def self.text_fields
        CONFIG.select { |_, t| t == TEXT }.keys
      end

      # Controlled term descriptive metadata fields
      def self.term_fields
        CONFIG.select { |_, t| t == TERM }.keys
      end

      def self.all
        CONFIG.keys
      end
    end

    Fields::CONFIG.each do |field, type|
      klass = "#{name}::#{type.to_s.titlecase}Field".constantize
      attribute field, Valkyrie::Types::Array.of(klass)
    end

    def to_export
      attributes.slice(*Fields.all).transform_values do |v|
        v.map(&:to_export)
      end
    end
  end
end
