# frozen_string_literal: true

module Premis
  # PREMIS Roles
  # https://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole.html
  class Roles < Vocabulary

    IMPLEMENTER = Types::Term['implementer',
                              'http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/imp']
    PROGRAM =     Types::Term['executing program',
                              'http://id.loc.gov/vocabulary/preservation/eventRelatedAgentRole/exe']
  end
end
