# frozen_string_literal: true

module Premis
  # PREMIS Outcomes
  # https://id.loc.gov/vocabulary/preservation/eventOutcome.html
  class Outcomes < Vocabulary

    FAILURE = Types::Term['fail',    'http://id.loc.gov/vocabulary/preservation/eventOutcome/fai']
    SUCCESS = Types::Term['success', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/suc']
    WARNING = Types::Term['warning', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/war']
  end
end
