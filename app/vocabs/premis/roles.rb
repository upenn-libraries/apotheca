# frozen_string_literal: true

module Premis
  # PREMIS Roles
  # https://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole.html
  module Roles
    include VocabTypes

    IMPLEMENTER = Term['implementer',       'http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/imp']
    PROGRAM =     Term['executing program', 'http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/exe']
  end
end
