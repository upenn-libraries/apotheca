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
        ).permit!
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
        expect(builder.fq.scan('AND').count).to eq 2
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
      ).permit!
    end

    it 'properly sets sort value' do
      expect(builder.sort).to eq 'title_ssi asc'
    end

    context 'with no sort parameters provided' do
      let(:params) { ActionController::Parameters.new({}) }
      let(:defaults) { { sort: { field: 'created_at', direction: 'desc' } } }

      it 'sets default sort value' do
        field = mapper::Sort::MAP.fetch(defaults.dig(:sort, :field).to_sym)
        expect(builder.sort).to eq("#{field} #{defaults.dig(:sort, :direction)}")
      end
    end

    context 'with cursor mark param' do
      let(:params) do
        ActionController::Parameters.new({ 'sort' => { 'field' => 'title', 'direction' => 'asc' },
                                           'cursorMark' => '*' }).permit!
      end

      it 'appends an additional sort ordering' do
        expect(builder.sort).to eq 'title_ssi asc, id asc'
      end
    end
  end

  describe '#search' do
    let(:params) do
      ActionController::Parameters.new(
        { 'search' => {
          'all' => 'blah',
          'fielded' => [
            { field: 'date', term: '1999', opr: '' },
            { field: 'name', term: 'Ruby', opr: 'required' },
            { field: 'subject', term: '', opr: 'excluded' }
          ]
        } }
      ).permit!
    end

    it 'properly composes a q param' do
      expect(builder.search).to eq '+(blah) date_tsim:"1999" +name_tsim:"Ruby"'
    end
  end

  describe '#start' do
    context 'with page and rows set' do
      let(:params) do
        ActionController::Parameters.new(
          { 'page' => '3', 'rows' => '20' }
        ).permit!
      end

      it 'sets the proper start value' do
        expect(builder.start).to eq 40
      end
    end

    context 'with no rows value set' do
      let(:default_rows) { mapper::ROWS_OPTIONS.min }
      let(:params) do
        ActionController::Parameters.new(
          { 'page' => '2' }
        ).permit!
      end

      it 'sets the proper start value' do
        expect(builder.start).to eq default_rows
      end
    end

    context 'with cursor mark param' do
      let(:params) { ActionController::Parameters.new({ 'rows' => '20', 'cursorMark' => '*' }).permit! }

      it 'sets the proper start value' do
        expect(builder.start).to eq 0
      end
    end
  end
end
