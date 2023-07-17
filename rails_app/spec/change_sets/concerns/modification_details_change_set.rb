# frozen_string_literal: true

shared_examples_for 'a ModificationDetailsChangeSet' do
  it 'sets created_by' do
    expect(change_set.created_by).not_to be_nil
  end

  it 'sets updated_by' do
    expect(change_set.updated_by).not_to be_nil
  end

  it 'sets date_created' do
    change_set.validate(date_created: DateTime.current)

    expect(change_set.date_created).not_to be_nil
  end

  it 'requires created_by' do
    change_set.validate(created_by: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors[:created_by]).to include 'can\'t be blank'
  end

  it 'requires updated_by' do
    change_set.validate(updated_by: nil)

    expect(change_set.valid?).to be false
    expect(change_set.errors[:updated_by]).to include 'can\'t be blank'
  end

  it 'ensures created_by is an email' do
    change_set.validate(created_by: 'invalid')

    expect(change_set.valid?).to be false
    expect(change_set.errors[:created_by]).to include 'is invalid'
  end

  it 'ensures updated_by is an email' do
    change_set.validate(updated_by: 'invalid')

    expect(change_set.valid?).to be false
    expect(change_set.errors[:updated_by]).to include 'is invalid'
  end
end
