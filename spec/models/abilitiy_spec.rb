# frozen_string_literal: true

require 'cancan/matchers'

describe 'Ability' do
  subject(:ability) { Ability.new(user) }

  context 'with no user' do
    let(:user) { nil }

    it { is_expected.not_to be_able_to(:view, :any) }
    it { is_expected.not_to be_able_to(:view, ItemResource) }
    it { is_expected.not_to be_able_to(:view, AssetResource) }
    it { is_expected.not_to be_able_to(:view, BulkExport) }
    it { is_expected.not_to be_able_to(:view, User) }
  end

  context 'with a viewer user' do
    let(:user) { create :user, :viewer }

    it { is_expected.to be_able_to(:read, BulkExport)}
    it { is_expected.to be_able_to(:read, ItemResource) }
    it { is_expected.to be_able_to(:read, AssetResource) }
    it { is_expected.not_to be_able_to(:edit, AssetResource) }
    it { is_expected.not_to be_able_to(:edit, ItemResource) }
    it { is_expected.not_to be_able_to(:create, BulkExport) }
    it { is_expected.not_to be_able_to(:update, BulkExport) }
    it { is_expected.not_to be_able_to(:destroy, BulkExport) }
    it { is_expected.not_to be_able_to(:view, User) }
  end

  context 'with an editor user' do
    let(:user) { create :user, :editor }
    let(:bulk_export) { create :bulk_export }

    it { is_expected.to be_able_to(:read, AssetResource) }
    it { is_expected.to be_able_to(:create, AssetResource) }
    it { is_expected.to be_able_to(:update, AssetResource) }
    it { is_expected.not_to be_able_to(:destroy, AssetResource) }

    it { is_expected.to be_able_to(:read, ItemResource) }
    it { is_expected.to be_able_to(:create, ItemResource) }
    it { is_expected.to be_able_to(:update, ItemResource) }
    it { is_expected.not_to be_able_to(:destroy, ItemResource) }

    it { is_expected.to be_able_to(:read, BulkExport) }
    it { is_expected.to be_able_to(:create, BulkExport) }
    it { is_expected.to be_able_to(:update, BulkExport) }
    it { is_expected.to be_able_to(:destroy, BulkExport) }
    it { is_expected.not_to be_able_to(:update, bulk_export) }
    it { is_expected.not_to be_able_to(:destroy, bulk_export) }

    it { is_expected.not_to be_able_to(:manage, User) }
  end

  context 'with an admin user' do
    let(:user) { create :user, :admin }

    it { is_expected.to be_able_to(:manage, :all) }
  end
end
