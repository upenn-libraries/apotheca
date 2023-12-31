# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Name field that includes value, uri and a list of roles (which are also controlled terms).
    class NameField < TermField
      transform_keys(&:to_sym)

      attribute :role, Valkyrie::Types::Array.of(TermField)

      def to_json_export
        super.tap do |hash|
          hash[:role] = role.map(&:to_json_export) if role.present?
        end
      end
    end
  end
end
