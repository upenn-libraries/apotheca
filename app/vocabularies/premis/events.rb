# frozen_string_literal: true

module Premis
  # PREMIS Events, a subset we care about
  # https://id.loc.gov/vocabulary/preservation/eventType.html
  class Events < Vocabulary
    INGEST =        Types::Term['ingestion',
                                'http://id.loc.gov/vocabulary/preservation/eventType/ing']
    CHECKSUM =      Types::Term['message digest calculation',
                                'http://id.loc.gov/vocabulary/preservation/eventType/mes']
    VIRUS_CHECK =   Types::Term['virus check',
                                'http://id.loc.gov/vocabulary/preservation/eventType/vir']
    EDIT_FILENAME = Types::Term['filename change',
                                'http://id.loc.gov/vocabulary/preservation/eventType/fil']
    FIXITY =        Types::Term['fixity',
                                'http://id.loc.gov/vocabulary/preservation/eventType/fix']
    TOMBSTONE =     Types::Term['deletion',
                                'http://id.loc.gov/vocabulary/preservation/eventType/del']
  end
end
