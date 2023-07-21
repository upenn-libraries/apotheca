# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    class Transformer
      # Abstract class that contains rules for mapping MARCXML documents to a json-based metadata schema. It
      # includes a class instance variable to keep track of mapping rules, methods to store rules and methods to
      # read rules. Currently, there are methods to support mapping rules for datafields and controlfields.
      #
      # For datafields and controlfields each rule:
      #   - must contain a tag parameter specifying the field to be moved
      #   - must contain a `:to` key, describing what top-level key the value should be mapped to
      #   - must contain a `:value` or `:uri` key, containing configuration describing how to pull the
      #       value for the value and uri fields respectively
      #   - can contain a `:if` key, containing a lambda that returns a truthy or falsey value, the lambda is passed
      #       the datafield or controlfield extracted from the xml document
      #   - can contain a `:custom` key, containing a lambda that applies additional transformations to the extracted
      #       values. The lambda is passed the datafield/controlfield, the extracted_values and the document. It must
      #       return the extracted values with any transformations applied.

      class MappingRules
        class << self
          def rules
            @rules ||= { datafield: {}, controlfield: {} }
          end

          def map_datafield(tag, **config)
            rules[:datafield][tag] ||= []
            rules[:datafield][tag] << config
          end

          def map_controlfield(tag, **config)
            rules[:controlfield][tag] ||= []
            rules[:controlfield][tag] << config
          end

          def rules_for(type, tag)
            rules[type].fetch(tag, [])
          end
        end
      end
    end
  end
end
