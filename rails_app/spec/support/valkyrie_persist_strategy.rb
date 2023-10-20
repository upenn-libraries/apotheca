# frozen_string_literal: true

# Defining custom FactoryBot strategy to persist Valkyrie resources.
#
# We were unable to use the `create` strategy because the default `create` strategy saves the object and
# doesn't return the new object. After persisting a resource, Valkyrie returns a new resource with the
# internal fields set. This conversation describes the problem we were running into with more
# detail: https://github.com/thoughtbot/factory_bot/pull/1437
#
# Additionally, this strategy persists any changes made in the after_create callback.
class ValkyriePersistStrategy
  DEFAULT_PERSISTER = :postgres_solr_persister

  def association(runner)
    runner.run
  end

  # TODO: allow users to override the persister in the evaluator?
  # @param [FactoryBot::Evaluation] evaluation
  def result(evaluation)
    instance = evaluation.object
    evaluation.notify(:after_build, instance)
    evaluation.notify(:before_create, instance)
    new_instance = persist(instance)
    evaluation.notify(:after_create, new_instance)
    persist(new_instance)
  end

  def persist(resource)
    raise 'Can only persist objects that are Valkyrie::Resource' unless resource.is_a? Valkyrie::Resource

    metadata_adapter = Valkyrie::MetadataAdapter.find(DEFAULT_PERSISTER)
    metadata_adapter.persister.save(resource: resource)
  end
end
