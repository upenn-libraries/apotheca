# frozen_string_literal: true

require 'cancan/matchers'

describe 'Ability' do
  subject(:ability) { Ability.new(user) }

  context 'with no user' do
    let(:user) { nil }

    it { is_expected.not_to be_able_to(:view, :all) }
  end

  context 'with a viewer user' do
    let(:user) { create :user, :viewer }

    it { is_expected.to be_able_to(:read, ItemResource) }
    it { is_expected.to be_able_to(:read, AssetResource) }
    it { is_expected.not_to be_able_to(:view, User) }
  end

  context 'with an editor user' do
    let(:user) { create :user, :editor }

    it { is_expected.to be_able_to(:manage, ItemResource) }
    it { is_expected.to be_able_to(:manage, AssetResource) }
    it { is_expected.not_to be_able_to(:manage, User) }
  end

  context 'with an admin user' do
    let(:user) { create :user, :admin }

    it { is_expected.to be_able_to(:manage, :all) }
  end
end
