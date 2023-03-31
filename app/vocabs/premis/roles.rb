module Premis
  module Roles
    Term = Data.define :label, :uri

    IMPLEMENTER = Term['implementer', 'http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/imp']
    PROGRAM = Term['executing program', 'http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/exe']
  end
end
