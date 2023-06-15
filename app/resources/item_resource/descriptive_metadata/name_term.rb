# frozen_string_literal: true
class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    class NameTerm < ControlledTerm
      attribute :role, Valkyrie::Types::Array.of(ControlledTerm)
    end
  end
end
