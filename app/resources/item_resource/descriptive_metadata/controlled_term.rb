# frozen_string_literal: true

class ItemResource
  class DescriptiveMetadata < Valkyrie::Resource
    # Resource storing label and uri to represent controlled terms.
    class ControlledTerm < Valkyrie::Resource
      attribute :label, Valkyrie::Types::Strict::String
      attribute :uri, Valkyrie::Types::URI
    end
  end
end
