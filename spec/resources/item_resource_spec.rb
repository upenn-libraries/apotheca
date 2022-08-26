# frozen_string_literal: true

require_relative 'concerns/modification_details'

describe ItemResource do
  let(:resource_klass) { described_class }
  let(:resource) { build(:item_resource) }

  it_behaves_like 'a Valkyrie::Resource'
  it_behaves_like 'ModificationDetails', :item_resource
end
