# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Resource storing label and uri to represent a controlled terms.
    class ControlledTerm < Valkyrie::Resource
      attribute :label, Valkyrie::Types::Strict::String
      attribute :uri, Valkyrie::Types::URI

      def to_export
        attributes.slice(:label, :uri)
      end
    end
  end
end
