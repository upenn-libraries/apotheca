# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Resource storing value and uri to represent a controlled terms.
    class TermField < Valkyrie::Resource
      transform_keys(&:to_sym)

      attribute :value, Valkyrie::Types::Strict::String
      attribute :uri, Valkyrie::Types::URI

      def to_json_export
        {
          value: value,
          uri: uri.to_s
        }
      end
    end
  end
end