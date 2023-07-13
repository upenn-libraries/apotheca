# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Resource storing label and uri to represent a controlled terms.
    class TextField < Valkyrie::Resource
      transform_keys(&:to_sym)

      attribute :value, Valkyrie::Types::Strict::String

      def to_export
        attributes.slice(:value)
      end
    end
  end
end
