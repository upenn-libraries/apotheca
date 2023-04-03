# frozen_string_literal: true

module Premis
  # PREMIS Outcomes
  # https://id.loc.gov/vocabulary/preservation/eventOutcome.html
  module Outcomes
    include VocabTypes

    FAILURE = Term['fail',    'http://id.loc.gov/vocabulary/preservation/eventOutcome/fai']
    SUCCESS = Term['success', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/suc']
    WARNING = Term['warning', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/war']
  end
end
