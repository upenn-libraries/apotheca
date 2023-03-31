module Premis
  module Events
    # https://docs.ruby-lang.org/en/3.2/Data.html
    # nicer than Struct
    Term = Data.define :label, :uri

    # Usage
    # Premis::Events::INGEST.uri
    # > 'http://id.loc.gov/vocabulary/preservation/eventType/ing'
    # Premis::Events::INGEST.to_h
    # > { label: 'ingestion', uri: 'http://id.loc.gov/vocabulary/preservation/eventType/ing' }

    INGEST = Term['ingestion', 'http://id.loc.gov/vocabulary/preservation/eventType/ing']
    CHECKSUM = Term['message digest calculation', 'http://id.loc.gov/vocabulary/preservation/eventType/mes']
    VIRUS_CHECK = Term['virus check', 'http://id.loc.gov/vocabulary/preservation/eventType/vir']
    EDIT_FILENAME = Term['filename change', 'http://id.loc.gov/vocabulary/preservation/eventType/fil']
    FIXITY = Term['fixity', 'http://id.loc.gov/vocabulary/preservation/eventType/fix']
    TOMBSTONE = Term['deletion', 'http://id.loc.gov/vocabulary/preservation/eventType/del']
  end
end
