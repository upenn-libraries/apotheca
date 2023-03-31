module Premis
  module Outcomes
    Term = Data.define :label, :uri

    FAILURE = Term['fail', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/fai']
    SUCCESS = Term['success', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/suc']
    WARNING = Term['warning', 'http://id.loc.gov/vocabulary/preservation/eventOutcome/war']
  end
end
