# frozen_string_literal: true

# Facilitate usage of controlled vocabulary terms, stored in YAML files
# Heavily inspired by Figgy's models/controlled_vocabulary.rb
class ControlledVocabulary
  class_attribute :vocabularies
  self.vocabularies = {}

  def self.register(key, klass)
    vocabularies[key] = klass
  end

  def self.for(key)
    vocabularies[key].new key: key
  end

  attr_reader :key

  def initialize(key:)
    @key = key
  end

  # override this
  def all
    []
  end

  def find(value)
    all.find { |t| t[:value] == value }
  end

  def find_by_label(label)
    all.find { |t| t[:label] == label }
  end

  def include?(value)
    find(value).present?
  end

  class PremisEvent < ControlledVocabulary
    ControlledVocabulary.register :premis_events, self
    def all
      @all ||= YAML.safe_load(Rails.root.join('config/vocabs/premis/events.yml').read, permitted_classes: [Symbol])
    end
  end

  class PremisEventOutcome < ControlledVocabulary
    ControlledVocabulary.register :premis_outcomes, self

    def all
      @all ||= YAML.safe_load(Rails.root.join('config/vocabs/premis/outcomes.yml').read, permitted_classes: [Symbol])
    end
  end
end
