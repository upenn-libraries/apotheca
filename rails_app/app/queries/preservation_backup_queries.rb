# frozen_string_literal: true

# Query class containing database queries related to preservation backup.
class PreservationBackupQueries
  def self.queries
    [:number_with_preservation_backup]
  end

  attr_reader :query_service

  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory

  def initialize(query_service:)
    @query_service = query_service
  end

  # Return the number of given Assets that have a preservation backup.
  def number_with_preservation_backup(ids)
    ids.map! do |id|
      id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
      raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID

      id.to_s
    end

    query = count_with_preservation_backup_query(ids)
    orm_class.count_by_sql(query)
  end

  private

  def count_with_preservation_backup_query(ids)
    ids_string = ids.map { |i| "'#{i}'" }.join(',')

    <<-SQL
        SELECT COUNT(*) FROM orm_resources
        WHERE internal_resource = 'AssetResource'
        AND id IN (#{ids_string})
        AND jsonb_array_length(metadata->'preservation_copies_ids') != 0
    SQL
  end
end

