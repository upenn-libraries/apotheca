module Asset
  class Operation < ResourceOperation

    def create_change_set(attributes)
      resource = attributes.delete(:resource) || AssetResource.new
      change_set = AssetChangeSet.new(resource)

      begin
        change_set.validate(attributes)
        Success(change_set)
      rescue StandardError => e
        Failure(error: :error_creating_change_set, exception: e)
      end
    end

    def add_preservation_events(change_set)
      AddPreservationEvents.new.call(change_set)
    end
  end
end