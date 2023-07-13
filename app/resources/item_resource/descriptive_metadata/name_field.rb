# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Name field that includes label, uri and a list of roles (which are also controlled terms).
    class NameField < TermField
      transform_keys(&:to_sym)

      attribute :role, Valkyrie::Types::Array.of(TermField)

      def to_export
        super.tap do |hash|
          hash[:role] = role.map(&:to_export)
        end
      end
    end
  end
end
