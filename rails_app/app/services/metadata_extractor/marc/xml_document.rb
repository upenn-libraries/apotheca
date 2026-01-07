# frozen_string_literal: true

module MetadataExtractor
  module MARC
    # Wrapper around MARC XML document to help parse out the different fields.
    class XMLDocument
      attr_reader :xml

      delegate_missing_to :xml

      # Initialize MARC XML document.
      #
      # @param marc_xml [String]
      def initialize(marc_xml)
        @xml = Nokogiri::XML(marc_xml)
        @xml.remove_namespaces!
      end

      # Return leader, controlfields and datafields.
      #
      # @return [Array<BaseField>]
      def fields
        @fields ||= [leader].compact + controlfields + datafields
      end

      # Return leader.
      #
      # @return [Leader, nil]
      def leader
        xml.at_xpath('//records/record/leader')&.then { |node| Leader.new(node, self) }
      end

      # Return all controlfields.
      #
      # @return [Array<ControlField>]
      def controlfields
        xml.xpath('//records/record/controlfield').map { |node| ControlField.new(node, self) }
      end

      # Return all datafields.
      #
      # @return [Array<Datafield>]
      def datafields
        xml.xpath('//records/record/datafield').map { |node| DataField.new(node, self) }
      end

      # Base class that implements methods shared by different field classes.
      class BaseField
        attr_reader :node, :document

        delegate_missing_to :node

        # Initialize MARC field and keep reference to original XML document.
        #
        # @param node [Nokogiri::XML::Element]
        # @param document [XMLDocument]
        def initialize(node, document)
          @node = node
          @document = document # Reference to entire MARC document
        end

        # Tag (name) assigned to field. Usually a three-digit string, but custom
        # Alma defined fields use a three-character string.
        #
        # @return [String]
        def tag
          attributes['tag'].value
        end

        # True if field is datafield.
        #
        # @return [Boolean]
        def datafield?
          type == :datafield
        end

        # True if field is controlfield.
        #
        # @return [Boolean]
        def controlfield?
          type == :controlfield
        end

        # True if field is leader.
        #
        # @return [Boolean]
        def leader?
          type == :leader
        end
      end

      # Wrapper class for data fields.
      class DataField < BaseField
        # Type of field.
        #
        # @return [Symbol]
        def type
          :datafield
        end

        # Return the value of indicator2.
        #
        # @return [String, nil]
        def indicator2
          attributes['ind2']&.value&.strip
        end

        # Returns the subfield value for the code given.
        #
        # @return [String, nil]
        def subfield_at(code)
          node.at_xpath("./subfield[@code='#{code}']")&.text
        end

        # Return subfield values for the subfield codes given.
        # If '*' is one of the values, all the subfield values are returned.
        #
        # @param subfields [Array|String|Range] subfield codes
        # @return [Array<String>]
        def values_at(subfields:)
          codes = Array(subfields)
          subfields = node.xpath('./subfield')

          if codes.first != '*'
            subfields = subfields.select do |s|
              codes.include?(s.attributes['code'].value)
            end
          end

          subfields.map { |v| v&.text&.strip }.compact_blank
        end
      end

      # Wrapper class for control fields.
      class ControlField < BaseField
        # Type of field.
        #
        # @return [Symbol]
        def type
          :controlfield
        end

        # Return an array of the values at the given locations.
        #
        # @param chars [Array|String|Range]
        # @return [Array<String>]
        def values_at(chars:)
          chars = Array(chars)
          text = node.text
          chars.map { |i| text.slice(i) }
        end
      end

      # Wrapper class for leader
      class Leader < ControlField
        # Type of field.
        #
        # @return [Symbol]
        def type
          :leader
        end
      end
    end
  end
end
