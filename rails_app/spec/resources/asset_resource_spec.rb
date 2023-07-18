# frozen_string_literal: true

require_relative 'concerns/modification_details'
require_relative 'concerns/lockable'

describe AssetResource do
  let(:resource_klass) { described_class }
  let(:resource) { build(:asset_resource) }

  it_behaves_like 'a Valkyrie::Resource'
  it_behaves_like 'ModificationDetails', :asset_resource
  it_behaves_like 'Lockable', :asset_resource
end
