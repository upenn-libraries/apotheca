# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennRules
      # Mapping MARC leader to AAT term.
      class PhysicalFormatLeader < Rules::FieldMapping
        ATLASES      = { value: 'atlases',                       uri: 'http://vocab.getty.edu/aat/300028053' }.freeze
        BOOKS        = { value: 'books',                         uri: 'http://vocab.getty.edu/aat/300028051' }.freeze
        CARTOGRAPHIC = { value: 'cartographic materials',        uri: 'http://vocab.getty.edu/aat/300028052' }.freeze
        EXCERPTS     = { value: 'excerpts',                      uri: 'http://vocab.getty.edu/aat/300026939' }.freeze
        GLOBES       = { value: 'globes (cartographic spheres)', uri: 'http://vocab.getty.edu/aat/300028089' }.freeze
        JOURNALS     = { value: 'journals (periodicals)',        uri: 'http://vocab.getty.edu/aat/300215390' }.freeze
        MAGAZINES    = { value: 'magazines (periodicals)',       uri: 'http://vocab.getty.edu/aat/300215389' }.freeze
        MANUSCRIPTS  = { value: 'manuscripts (documents)',       uri: 'http://vocab.getty.edu/aat/300028569' }.freeze
        MAPS         = { value: 'maps (documents)',              uri: 'http://vocab.getty.edu/aat/300028094' }.freeze
        NEWSLETTERS  = { value: 'newsletters',                   uri: 'http://vocab.getty.edu/aat/300026652' }.freeze
        NEWSPAPERS   = { value: 'newspapers',                    uri: 'http://vocab.getty.edu/aat/300026656' }.freeze
        PERIODICALS  = { value: 'periodicals',                   uri: 'http://vocab.getty.edu/aat/300026657' }.freeze
        SCORES       = { value: 'scores (documents for music)',  uri: 'http://vocab.getty.edu/aat/300026427' }.freeze
        SERIALS      = { value: 'serials (publications)',        uri: 'http://vocab.getty.edu/aat/300026642' }.freeze
        SHEET_MUSIC  = { value: 'sheet music',                   uri: 'http://vocab.getty.edu/aat/300026430' }.freeze

        # For each mapping below, the AAT term should be applied if the MARC fields match ALL the
        # values (e.g. add "books" AAT term only if MARC Leader pos. 6="a" AND Leader pos. 7="a" OR "m")
        MAPPINGS = [
          { term: BOOKS,        leader: { 6 => [:a],    7 => %i[a m] }, control008: {} },
          { term: CARTOGRAPHIC, leader: { 6 => %i[e f], 7 => %i[m s] }, control008: {} },
          { term: MAPS,         leader: { 6 => %i[e f], 7 => %i[m s] }, control008: { 25 => %i[a b c] } },
          { term: ATLASES,      leader: { 6 => %i[e f], 7 => %i[m s] }, control008: { 25 => [:e] } },
          { term: GLOBES,       leader: { 6 => %i[e f], 7 => %i[m s] }, control008: { 25 => [:d] } },
          { term: SERIALS,      leader: { 6 => [:a],    7 => %i[b i s] }, control008: {} },
          { term: NEWSPAPERS,   leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:n] } },
          { term: PERIODICALS,  leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:p] } },
          { term: MAGAZINES,    leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:g] } },
          { term: JOURNALS,     leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:j] } },
          { term: NEWSLETTERS,  leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:s] } },
          { term: MANUSCRIPTS,  leader: { 6 => %i[d f t]               }, control008: {} },
          { term: SCORES,       leader: { 6 => %i[c d]                 }, control008: {} }
        ].freeze

        # Maps leader and control008 fields to one or more physical formats.
        #
        # @param leader [MetadataExtractor::MARC::XMLDocument::Leader]
        # @return [Array<Hash>] list of extracted values in hash containing value and uri
        def transform(leader)
          control008 = leader.document.at_xpath("//records/record/controlfield[@tag='008']").text
          leader = leader.text

          map(leader, control008)
        end

        # Only maps leader.
        #
        # @param field [MetadataExtractor::MARC::XMLDocument::BaseField]
        # @return [Boolean]
        def transform?(field)
          field.leader?
        end

        private

        # Maps MARC leader and control 008 field to AAT terms. May return zero or more values.
        #
        # @param [String] leader field
        # @param [String] control008 field
        # @return [Array<Hash>]
        def map(leader, control008)
          # @see MAPPINGS
          MAPPINGS.filter_map do |rule|
            match(rule[:leader], leader) && match(rule[:control008], control008) ? rule[:term] : nil
          end
        end

        # Returns true if the field matches the conditions given.
        #
        # @param [Hash<Integer, Array<Symbol>>] conditions
        # @param [String] field
        # @return [Boolean]
        def match(conditions, field)
          conditions.compact_blank.all? do |index, values|
            char = field[index]

            values.include?(char&.to_sym)
          end
        end
      end
    end
  end
end
