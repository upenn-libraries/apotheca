# frozen_string_literal: true

module MetadataExtractor
  module MARC
    # Rules for mapping Penn's MARC XML to Apotheca's descriptive metadata schema.
    class PennRules < Rules
      field_mapping PhysicalFormatLeader, to: :physical_format

      field_mapping DateField, tag: '008', to: :date
      field_mapping LanguageField, tag: '008', chars: 35..37, to: :language

      field_mapping LanguageField, tag: '041', subfields: %w[a b g], to: :language
      field_mapping NameField, tag: '100', subfields: %w[a b c d g j q], uri: true, to: :name
      field_mapping NameField, tag: '110', subfields: %w[a b c d g n], uri: true, to: :name
      field_mapping NameField, tag: '111', subfields: %w[a c d e g n q], uri: true, to: :name
      field_mapping DataField, tag: '245', subfields: %w[a b f g k n p s], to: :title
      field_mapping DataField, tag: '246', subfields: %w[a b n p], to: :alt_title
      field_mapping DataField, tag: '260', subfields: 'b', to: :publisher
      field_mapping DataField, tag: '264', subfields: 'b', indicator2: '1', to: :publisher
      field_mapping DataField, tag: '300', subfields: %w[a b c e f g], to: :extent
      field_mapping ItemTypeField, tag: '336', subfields: 'a', to: :item_type
      field_mapping DataField, tag: '500', subfields: 'a', to: :note
      field_mapping DataField, tag: '501', subfields: 'a', to: :note
      field_mapping DataField, tag: '502', subfields: 'a'..'o', to: :note
      field_mapping DataField, tag: '505', prefix: 'Table of contents: ', to: :note
      field_mapping DataField, tag: '520', subfields: %w[a b], to: :description
      field_mapping DataField, tag: '542', subfields: 'a'..'s', to: :note
      field_mapping DataField, tag: '545', subfields: %w[a b u], to: :note
      field_mapping DataField, tag: '546', subfields: %w[a b], to: :note
      field_mapping DataField, tag: '561', subfields: 'a', to: :provenance
      field_mapping DataField, tag: '590', subfields: 'a', to: :note
      field_mapping DataField, tag: '600', subfields: 'a'..'z', uri: true, to: :subject
      field_mapping DataField, tag: '610', subfields: 'a'..'z', join: ' -- ', uri: true, to: :subject
      field_mapping DataField, tag: '648', subfields: %w[a y], join: ' -- ', uri: true, to: :coverage
      field_mapping DataField, tag: '650', subfields: 'a'..'z', join: ' -- ', uri: true, to: :subject
      field_mapping DataField, tag: '650', subfields: 'y', to: :coverage
      field_mapping DataField, tag: '651', subfields: 'a'..'z', join: ' -- ', uri: true, to: :geographic_subject
      field_mapping DataField, tag: '651', subfields: 'y', to: :coverage
      field_mapping PhysicalFormatField, tag: '655', subfields: 'a', uri: true, to: :physical_format
      field_mapping AdditionalNameField, tag: '700', subfields: %w[a b c d g j q], uri: true, to: :name
      field_mapping ProvenanceNameField, tag: '700', subfields: %w[a b c d e], to: :provenance
      field_mapping RelatedWorkField, tag: '700', subfields: 'a'..'z', to: :note
      field_mapping AdditionalNameField, tag: '710', subfields: %w[a b c d g n], uri: true, to: :name
      field_mapping RelatedWorkField, tag: '710', subfields: 'a'..'z', to: :note
      field_mapping AdditionalNameField, tag: '711', subfields: %w[a c d e g n q], uri: true, to: :name
      field_mapping RelatedWorkField, tag: '711', subfields: 'a'..'z', to: :note
      field_mapping DataField, tag: '752', subfields: %w[a b c d f g h], join: ' -- ', uri: true, to: :location
      field_mapping DataField, tag: '773', subfields: 't', to: :collection
      field_mapping DataField, tag: '856', subfields: %w[u z 3], join: ': ', to: :relation
      field_mapping TransliteratedTitleField, tag: '880', subfields: %w[a b f g k n p s], to: :title

      field_mapping PhysicalLocationField, tag: 'AVA', to: :physical_location

      cleanup TrimPunctuation,  fields: %i[collection title subject geographic_subject
                                           physical_format publisher name coverage]
      cleanup RemoveDuplicates, fields: %i[subject name language physical_format coverage]
    end
  end
end
