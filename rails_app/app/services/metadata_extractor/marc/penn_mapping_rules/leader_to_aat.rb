# frozen_string_literal: true

module MetadataExtractor
  module MARC
    class PennMappingRules
      # Module that contains rules for mapping leader and control fields to appropriate AAT terms.
      module LeaderToAAT
        # For each rule below, the AAT term should be applied if the MARC fields match ALL the
        # values (e.g. add "books" AAT term only if MARC Leader pos. 6="a" AND Leader pos. 7="a" OR "m")
        RULES = [
          { term: AAT::BOOKS,        leader: { 6 => [:a],    7 => %i[a m] }, control008: {} },
          { term: AAT::CARTOGRAPHIC, leader: { 6 => %i[e f], 7 => %i[m s] }, control008: {} },
          { term: AAT::MAPS,         leader: { 6 => %i[e f], 7 => %i[m s] }, control008: { 25 => %i[a b c] } },
          { term: AAT::ATLASES,      leader: { 6 => %i[e f], 7 => %i[m s] }, control008: { 25 => [:e] } },
          { term: AAT::GLOBES,       leader: { 6 => %i[e f], 7 => %i[m s] }, control008: { 25 => [:d] } },
          { term: AAT::SERIALS,      leader: { 6 => [:a],    7 => %i[b i s] }, control008: {} },
          { term: AAT::NEWSPAPERS,   leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:n] } },
          { term: AAT::PERIODICALS,  leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:p] } },
          { term: AAT::MAGAZINES,    leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:g] } },
          { term: AAT::JOURNALS,     leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:j] } },
          { term: AAT::NEWSLETTERS,  leader: { 6 => [:a],    7 => %i[b i s] }, control008: { 21 => [:s] } },
          { term: AAT::MANUSCRIPTS,  leader: { 6 => %i[d f t]               }, control008: {} },
          { term: AAT::SCORES,       leader: { 6 => %i[c d]                 }, control008: {} }
        ].freeze

        # Maps MARC leader and control 008 field to AAT terms. May return zero or more values.
        #
        # @param [String] leader field
        # @param [String] control008 field
        # @return [Array<Hash>]
        def self.map(leader, control008)
          # @see RULES
          RULES.filter_map do |rule|
            match(rule[:leader], leader) && match(rule[:control008], control008) ? rule[:term] : nil
          end
        end

        # Returns true if the field matches the conditions given.
        #
        # @param [Hash<Integer, Array<Symbol>>] conditions
        # @param [String] field
        # @return [Boolean]
        def self.match(conditions, field)
          conditions.compact_blank.all? do |index, values|
            char = field[index]

            values.include?(char&.to_sym)
          end
        end
      end
    end
  end
end
