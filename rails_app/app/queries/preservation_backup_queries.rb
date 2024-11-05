# frozen_string_literal: true

# Query class containing database queries related to preservation backup.
class PreservationBackupQueries
  def self.queries
    [:number_with_preservation_backup,
     :missing_preservation_backup]
  end

  attr_reader :query_service

  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory

  def initialize(query_service:)
    @query_service = query_service
  end

  # Returns list of AssetResource that are missing a preservation backup.
  #
  # @return [Enumerator::Lazy<AssetResource>]
  def missing_preservation_backup
    orm_class.where(internal_resource: ItemResource.to_s).find_each.lazy.flat_map do |orm_object|
      query = assets_without_preservation_backup_query(orm_object.id)
      run_query(query)
    end
  end

  # Return the number of given Assets that have a preservation backup.
  def number_with_preservation_backup(ids)
    return 0 if ids.blank?

    ids.map! do |id|
      id = Valkyrie::ID.new(id.to_s) if id.is_a?(String)
      raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID

      id.to_s
    end

    query = count_with_preservation_backup_query(ids)
    orm_class.count_by_sql(query)
  end

  private

  # Given an Item's id, find any of its related Assets that are missing a preservation backup.
  def assets_without_preservation_backup_query(item_id)
    <<-SQL
        SELECT DISTINCT member.* FROM orm_resources a,
        jsonb_array_elements(a.metadata->'asset_ids') AS b(member)
        JOIN orm_resources member ON (b.member->>'id')::#{orm_class.columns_hash["id"].type} = member.id 
        WHERE a.id = '#{item_id}' 
        AND member.internal_resource = 'AssetResource'
        AND jsonb_array_length(member.metadata->'preservation_file_id') = 1
        AND jsonb_array_length(member.metadata->'preservation_copies_ids') = 0
      SQL
  end


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
