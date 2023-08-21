# frozen_string_literal: true

describe User do
  it 'requires an email' do
    user = described_class.new email: nil
    expect(user.valid?).to be false
    expect(user.errors['email']).to include "can't be blank"
  end

  it 'requires a unique email' do
    create(:user, :viewer, email: 'test@upenn.edu')
    user = build(:user, :viewer, email: 'test@upenn.edu')
    expect(user.valid?).to be false
    expect(user.errors['email']).to include 'has already been taken'
  end

  it 'requires a unique set of omniauth fields' do
    create(:user, :viewer, email: 'test@upenn.edu', provider: 'ldap', uid: 'test')
    create(:user, :admin, email: 'another@upenn.edu', provider: 'saml', uid: 'test')
    user = build(:user, :editor, email: 'more@upenn.edu', provider: 'ldap', uid: 'test')
    expect(user.valid?).to be false
    expect(user.errors['uid']).to include 'has already been taken'
  end

  it 'must have a role' do
    user = build(:user, roles: [])
    expect(user.valid?).to be false
    expect(user.errors['roles']).to include 'must be set for a User'
  end

  it 'requires role names to be in the configured list' do
    user = build(:user, roles: ['unconfigured'])
    expect(user.valid?).to be false
    expect(user.errors['roles']).to include 'is not included in the list'
  end

  it 'requires role to be single-valued' do
    user = create(:user, :editor)
    user.roles << 'admin'
    expect(user.valid?).to be false
    expect(user.errors['roles']).to include 'cannot be multivalued'
  end

  it 'de-duplicates roles on save' do
    user = create(:user, :admin)
    user.roles << 'admin'
    user.save
    expect(user.roles).to eq ['admin']
  end

  describe '.from_omniauth_saml' do
    context 'with a stub PennKey user' do
      let(:user) { create(:user, :stub, :admin, uid: 'stub@upenn.edu', email: 'stub@upenn.edu')}
      let(:auth_info) do
        OpenStruct.new({ provider: user.provider,
                              info: OpenStruct.new({ uid: user.uid, first_name: 'F', last_name: 'L' }) })
      end

      it 'returns a user with updated name attributes' do
        returned_user = described_class.from_omniauth_saml(auth_info)
        expect(returned_user).to eq returned_user
        expect(returned_user).to be_changed
      end
    end

    context 'with an existing PennKey user' do
      let(:user) { create(:user, :admin, email: 'test@upenn.edu', uid: 'test@upenn.edu') }
      let(:auth_info) { OpenStruct.new({ provider: user.provider, info: OpenStruct.new({ uid: user.uid }) }) }

      it 'returns an unmodified, persisted User' do
        returned_user = described_class.from_omniauth_saml(auth_info)
        expect(returned_user).to eq returned_user
        expect(returned_user).not_to be_changed
      end
    end

    context 'with a PennKey user not configured for access' do
      let(:auth_info) { OpenStruct.new({ provider: 'test', info: OpenStruct.new({ uid: 'zzzzzzz' }) }) }

      it 'returns a nil user' do
        expect(described_class.from_omniauth_saml(auth_info)).to be_nil
      end
    end
  end
end
