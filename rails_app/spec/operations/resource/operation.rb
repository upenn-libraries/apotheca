# frozen_string_literal: true

shared_examples_for 'operation' do
  let(:operation) { described_class.new }

  describe '#change_set_class' do
    it 'returns change_set class' do
      expect(operation.change_set_class).to be_a Class
      expect(operation.change_set_class.superclass).to eq ChangeSet
    end
  end

  describe '#resource_class' do
    it 'returns resource class' do
      expect(operation.resource_class).to be_a Class
      expect(operation.resource_class.superclass).to eq Valkyrie::Resource
    end
  end
end
