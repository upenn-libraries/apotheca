# frozen_string_literal: true

# Provides access to query services
module Query
  # @return [Valkyrie::Persistence::Solr::QueryService]
  def self.solr
    @solr ||= Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  # @return [Valkyrie::Persistence::Postgres::QueryService]
  def self.postgres
    @postgres ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
