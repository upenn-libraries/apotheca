# Shared parent class that contains helper steps that can be used for all Resource operations (Item, Assets).
class ResourceOperation < Dry::Operation
  def set_updated_by(change_set)
    change_set.updated_by = change_set.created_by if change_set.updated_by.blank?

    Success(change_set)
  end

  def validation(change_set)
    if change_set.valid?
      Success(change_set)
    else
      Failure(error: :validation_failed, change_set: change_set)
    end
  end

  def save(change_set)
    resource = change_set.sync

    begin
      saved_resource = persister.save(resource: resource)
      Success(saved_resource)
    rescue StandardError => e
      Failure(error: :error_saving_resource, exception: e, change_set: change_set)
    end
  end

  private

  def persister
    Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
  end
end