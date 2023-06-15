# frozen_string_literal: true

class ItemResource
  # Descriptive metadata for Item.
  class DescriptiveMetadata < Valkyrie::Resource
    # All descriptive metadata fields
    FREE_TEXT_FIELDS = %i[
      alt_title bibnumber collection coverage date description extent identifier note
      physical_location provenance publisher relation title
    ].freeze

    CONTROLLED_TERM_FIELDS = %i[
      format item_type geographic_subject language location rights subject
    ].freeze

    FREE_TEXT_FIELDS.each do |field|
      attribute field, Valkyrie::Types::Array.of(Valkyrie::Types::Strict::String)
    end

    CONTROLLED_TERM_FIELDS.each do |field|
      attribute field, Valkyrie::Types::Array.of(ControlledTerm)
    end

    attribute :name, Valkyrie::Types::Array.of(NameTerm)

    def to_export
      attributes.slice(*FREE_TEXT_FIELDS, *CONTROLLED_TERM_FIELDS, :name)
    end
  end
end