# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Resource text value in hash to support additional nested values in the future..
    class TextField < Valkyrie::Resource
      transform_keys(&:to_sym)

      attribute :value, Valkyrie::Types::Strict::String

      def to_export
        attributes.slice(:value)
      end
    end
  end
end
