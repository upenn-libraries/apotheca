# frozen_string_literal: true

shared_examples_for 'a LockableChangeSet' do |change_set_class|
  let(:persister) { Valkyrie::MetadataAdapter.find(:postgres).persister }
  let(:persisted_resource) { persister.save(resource: resource) }

  context 'when a lock token is invalid' do
    before do
      change_set = change_set_class.new(persisted_resource)
      change_set.validate(updated_by: 'someuser@upenn.edu')
      persister.save(resource: change_set.sync)
    end

    it 'raises an exception on save' do
      change_set2 = change_set_class.new(persisted_resource)
      change_set2.validate(updated_by: 'anohteruser@upenn.edu')
      expect { persister.save(resource: change_set2.sync) }.to raise_exception Valkyrie::Persistence::StaleObjectError
    end
  end
end
