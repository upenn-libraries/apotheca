# frozen_string_literal: true

describe User, type: :model do
  it 'requires an email' do
    user = described_class.new email: nil
    expect(user.valid?).to be false
    expect(user.errors['email']).to include "can't be blank"
  end

  it 'requires a unique email' do
    create :user, :viewer, email: 'test@upenn.edu'
    user = build :user, :viewer, email: 'test@upenn.edu'
    expect(user.valid?).to be false
    expect(user.errors['email']).to include 'has already been taken'
  end

  it 'requires a unique set of omniauth fields' do
    create :user, :viewer, email: 'test@upenn.edu', provider: 'ldap', uid: 'test'
    create :user, :admin, email: 'another@upenn.edu', provider: 'saml', uid: 'test'
    user = build :user, :editor, email: 'more@upenn.edu', provider: 'ldap', uid: 'test'
    expect(user.valid?).to be false
    expect(user.errors['uid']).to include 'has already been taken'
  end

  it 'must have a role' do
    user = build :user, roles: []
    expect(user.valid?).to be false
    expect(user.errors['roles']).to include 'must be set for a User'
  end

  it 'requires role names to be in the configured list' do
    user = build :user, roles: ['unconfigured']
    expect(user.valid?).to be false
    expect(user.errors['roles']).to include 'is not included in the list'
  end

  it 'requires role to be single-valued' do
    user = create :user, :editor
    user.roles << 'admin'
    expect(user.valid?).to be false
    expect(user.errors['roles']).to include 'cannot be multivalued'
  end

  it 'de-duplicates roles on save' do
    user = create :user, :admin
    user.roles << 'admin'
    user.save
    expect(user.roles).to eq ['admin']
  end

  it "can't have more than 10 bulk exports" do
    user = create :user, :admin
    create_list(:bulk_export, 11, user: user)
    user.reload
    expect(user.valid?).to be false
    expect(user.errors[:bulk_exports]).to include('Too many Bulk Exports, maximum is 10.')
  end
end
