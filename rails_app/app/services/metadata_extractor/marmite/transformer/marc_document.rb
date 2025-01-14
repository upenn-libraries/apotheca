# frozen_string_literal: true

module MetadataExtractor
  class Marmite
    class Transformer
      # Wrapper around MARC XML document to help parse out the different fields.
      class MARCDocument
        VALUES_PARAMS = %i[subfields chars].freeze

        attr_reader :xml

        delegate_missing_to :xml

        def initialize(marc_xml)
          @xml = Nokogiri::XML(marc_xml)
          @xml.remove_namespaces!
        end

        def controlfields
          xml.xpath('//records/record/controlfield').map { |node| ControlField.new(node) }
        end

        def datafields
          xml.xpath('//records/record/datafield').map { |node| DataField.new(node) }
        end

        # Base class that implements methods shared by different field classes.
        class BaseField
          attr_reader :node

          delegate_missing_to :node

          def initialize(node)
            @node = node
          end

          def tag
            attributes['tag'].value
          end
        end

        # Wrapper class for data fields.
        class DataField < BaseField
          # Return field type.
          def type
            :datafield
          end

          # Return the value of indicator2
          def indicator2
            attributes['ind2']&.value&.strip
          end

          # Returns the subfield value for the code given. If no subfield with that code is present return `nil`.
          def subfield_at(code)
            node.at_xpath("./subfield[@code='#{code}']")&.text
          end

          # Return subfield values for the subfield codes given.
          # If '*' is one of the values, all the subfield values are returned.
          #
          # @param subfields [Array|String] subfield codes
          # @return [Array<String>]
          def values_at(subfields:)
            codes = Array.wrap(subfields)
            subfields = node.xpath('./subfield')

            if codes.first != '*'
              subfields = subfields.select do |s|
                codes.include?(s.attributes['code'].value)
              end
            end

            subfields.map { |v| v&.text&.strip }.compact_blank!
          end
        end

        # Wrapper class for control fields.
        class ControlField < BaseField
          # Return field type.
          def type
            :controlfield
          end

          # Return an array of the values at the given locations.
          #
          # @param chars [Array|String]
          # @return [Array<String>]
          def values_at(chars:)
            chars = Array.wrap(chars)
            text = node.text
            chars.map { |i| text.slice(i) }
          end
        end
      end
    end
  end
end
