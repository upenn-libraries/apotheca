# frozen_string_literal: true

module Premis
  # PREMIS Events, a subset we care about
  # https://id.loc.gov/vocabulary/preservation/eventType.html
  module Events
    include VocabTypes

    INGEST =        Term['ingestion',
                         'http://id.loc.gov/vocabulary/preservation/eventType/ing']
    CHECKSUM =      Term['message digest calculation',
                         'http://id.loc.gov/vocabulary/preservation/eventType/mes']
    VIRUS_CHECK =   Term['virus check',
                         'http://id.loc.gov/vocabulary/preservation/eventType/vir']
    EDIT_FILENAME = Term['filename change',
                         'http://id.loc.gov/vocabulary/preservation/eventType/fil']
    FIXITY =        Term['fixity',
                         'http://id.loc.gov/vocabulary/preservation/eventType/fix']
    TOMBSTONE =     Term['deletion',
                         'http://id.loc.gov/vocabulary/preservation/eventType/del']
  end
end
