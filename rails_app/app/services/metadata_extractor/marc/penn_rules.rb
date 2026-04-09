# frozen_string_literal: true

module MetadataExtractor
  module MARC
    # Rules for mapping Penn's MARC XML to Apotheca's descriptive metadata schema.
    class PennRules < Rules
      add_rules field: :alt_title do |field|
        field.mapping DataField, tag: '246', subfields: %w[a b n p]
      end

      add_rules field: :collection do |field|
        field.mapping CollectionNameField, tag: '710', subfields: 'a'
        field.mapping DataField, tag: '773', subfields: 't'
        field.cleanup TrimPunctuation
      end

      add_rules field: :coverage do |field|
        field.mapping DataField, tag: '648', subfields: %w[a y], join: ' -- ', uri: true
        field.mapping DataField, tag: '650', subfields: 'y'
        field.mapping DataField, tag: '651', subfields: 'y'
        field.cleanup TrimPunctuation
        field.cleanup RemoveDuplicates
      end

      add_rules field: :date do |field|
        field.mapping DateField, tag: '008'
      end

      add_rules field: :description do |field|
        field.mapping DataField, tag: '520', subfields: %w[a b]
      end

      add_rules field: :extent do |field|
        field.mapping DataField, tag: '300', subfields: %w[a b c e f g]
      end

      add_rules field: :geographic_subject do |field|
        field.mapping DataField, tag: '651', subfields: 'a'..'z', join: ' -- ', uri: true
        field.cleanup TrimPunctuation
      end

      add_rules field: :item_type do |field|
        field.mapping ItemTypeField, tag: '336', subfields: 'a'
      end

      add_rules field: :language do |field|
        field.mapping LanguageField, tag: '008', chars: 35..37
        field.mapping LanguageField, tag: '041', subfields: %w[a b g]
        field.cleanup RemoveDuplicates
      end

      add_rules field: :location do |field|
        field.mapping DataField, tag: '752', subfields: %w[a b c d f g h], join: ' -- ', uri: true
      end

      add_rules field: :name do |field|
        field.mapping NameField, tag: '100', subfields: %w[a b c d g j q], uri: true
        field.mapping NameField, tag: '110', subfields: %w[a b c d g n], uri: true
        field.mapping NameField, tag: '111', subfields: %w[a c d e g n q], uri: true
        field.mapping AdditionalNameField, tag: '700', subfields: %w[a b c d g j q], uri: true
        field.mapping AdditionalNameField, tag: '710', subfields: %w[a b c d g n], uri: true
        field.mapping AdditionalNameField, tag: '711', subfields: %w[a c d e g n q], uri: true
        field.cleanup TrimPunctuation
        field.cleanup RemoveDuplicates
      end

      add_rules field: :note do |field|
        field.mapping DataField, tag: '500', subfields: 'a'
        field.mapping DataField, tag: '501', subfields: 'a'
        field.mapping DataField, tag: '502', subfields: 'a'..'o'
        field.mapping DataField, tag: '505', prefix: 'Table of contents: '
        field.mapping DataField, tag: '542', subfields: 'a'..'s'
        field.mapping DataField, tag: '545', subfields: %w[a b u]
        field.mapping DataField, tag: '546', subfields: %w[a b]
        field.mapping DataField, tag: '580', subfields: 'a'
        field.mapping DataField, tag: '590', subfields: 'a'
        field.mapping RelatedWorkField, tag: '700', subfields: 'a'..'z'
        field.mapping RelatedWorkField, tag: '710', subfields: 'a'..'z'
        field.mapping RelatedWorkField, tag: '711', subfields: 'a'..'z'
      end

      add_rules field: :physical_format do |field|
        field.mapping PhysicalFormatLeader
        field.mapping PhysicalFormatField, tag: '655', subfields: 'a', uri: true
        field.cleanup TrimPunctuation
        field.cleanup RemoveDuplicates
      end

      add_rules field: :provenance do |field|
        field.mapping DataField, tag: '561', subfields: 'a'
        field.mapping LegacyProvenanceField, tag: '650', subfields: 'a'
        field.mapping ProvenanceNameField, tag: '700', subfields: %w[a b c d e g j q]
        field.mapping ProvenanceNameField, tag: '710', subfields: %w[a b c d e g n]
      end

      add_rules field: :publisher do |field|
        field.mapping DataField, tag: '260', subfields: 'b'
        field.mapping DataField, tag: '264', subfields: 'b', indicator2: '1'
        field.cleanup TrimPunctuation
      end

      add_rules field: :subject do |field|
        field.mapping DataField, tag: '600', subfields: 'a'..'z', uri: true
        field.mapping DataField, tag: '610', subfields: 'a'..'z', join: ' -- ', uri: true
        field.mapping ExcludeLegacyValuesField, tag: '650', subfields: 'a'..'z', join: ' -- ', uri: true
        field.cleanup TrimPunctuation
        field.cleanup RemoveDuplicates
      end

      add_rules field: :title do |field|
        field.mapping DataField, tag: '245', subfields: %w[a b f g k n p s]
        field.mapping TransliteratedTitleField, tag: '880', subfields: %w[a b f g k n p s]
        field.cleanup TrimPunctuation
      end

      add_rules field: :relation do |field|
        field.mapping DataField, tag: '856', subfields: %w[u z 3], join: ': '
      end

      add_rules field: :physical_location do |field|
        field.mapping PhysicalLocationField, tag: 'AVA'
      end
    end
  end
end
