# frozen_string_literal: true

describe Solr::QueryBuilder do
  let(:builder) { described_class.new(params: params, defaults: defaults) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:defaults) { {} }

  describe '#fq' do
    context 'with multiple filters provided' do
      let(:defaults) do
        { fq: { resource: ['item'] } }
      end
      let(:params) do
        ActionController::Parameters.new(
          { 'filters' => { 'empty' => '', 'string' => 'test', 'array' => %w[a b] } }
        )
      end

      it 'includes a default' do
        expect(builder.fq).to include 'resource: "item"'
      end

      it 'does not include empty values' do
        expect(builder.fq).not_to include 'empty'
      end

      it 'properly sets single filter value' do
        expect(builder.fq).to include 'string: "test"'
      end

      it 'properly joins clauses with AND' do
        expect(builder.fq.scan(/AND/).count).to eq 2
      end

      it 'properly sets a filter with multiple values' do
        expect(builder.fq).to include '(array: "a" OR array: "b")'
      end
    end
  end

  describe '#sort' do
    let(:params) { { 'sort_field' => 'field', 'sort_direction' => 'desc' } }

    it 'properly sets sort value' do
      expect(builder.sort).to eq 'field desc'
    end
  end
end
