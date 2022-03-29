# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'requires an email' do
    user = described_class.new email: nil
    expect(user.valid?).to be false
    expect(user.errors['email']).to include "can't be blank"
  end

  it 'requires a unique email' do
    described_class.create email: 'test@upenn.edu'
    user = described_class.new email: 'test@upenn.edu'
    expect(user.valid?).to be false
    expect(user.errors['email']).to include 'has already been taken'
  end

  it 'requires a unique set of omniauth fields' do
    described_class.create email: 'test@upenn.edu', provider: 'ldap', uid: 'test'
    described_class.create email: 'another@upenn.edu', provider: 'saml', uid: 'test'
    user = described_class.new email: 'more@upenn.edu', provider: 'ldap', uid: 'test'
    expect(user.valid?).to be false
    expect(user.errors['uid']).to include 'has already been taken'
  end
end
