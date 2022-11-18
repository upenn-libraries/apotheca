# frozen_string_literal: true

describe Solr::QueryBuilder do
  let(:builder) { described_class.new(params: params, defaults: defaults, mapper: mapper) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:defaults) { {} }
  let(:mapper) { Solr::QueryMaps::Item }

  describe '#fq' do
    context 'with multiple filters provided' do
      let(:defaults) do
        { fq: { item_type: ['item'] } }
      end
      let(:params) do
        ActionController::Parameters.new(
          { 'filter' => { 'format' => '', 'collection' => 'test', 'subject' => %w[a b] } }
        )
      end

      it 'includes a default' do
        expect(builder.fq).to include 'item_type_ssim: "item"'
      end

      it 'does not include empty values' do
        expect(builder.fq).not_to include 'format'
      end

      it 'properly sets single filter value' do
        expect(builder.fq).to include 'collection_ssim: "test"'
      end

      it 'properly joins clauses with AND' do
        expect(builder.fq.scan(/AND/).count).to eq 2
      end

      it 'properly sets a filter with multiple values' do
        expect(builder.fq).to include '(subject_ssim: "a" OR subject_ssim: "b")'
      end
    end
  end

  describe '#sort' do
    let(:params) do
      ActionController::Parameters.new(
        { 'sort' => { 'field' => 'title', 'direction' => 'asc' } }
      )
    end

    it 'properly sets sort value' do
      expect(builder.sort).to eq 'title_ssi asc'
    end
  end

  describe '#search' do
    let(:params) do
      ActionController::Parameters.new(
        { 'search' => {
          'all' => 'blah',
          'field' => %w[date subject],
          'value' => %w[1999 Ruby]
        } }
      ).permit!
    end

    it 'properly composes a q param' do
      expect(builder.search).to eq 'blah AND date_tsim:1999 AND subject_tsim:Ruby'
    end
  end
end
