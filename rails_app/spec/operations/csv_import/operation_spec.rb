# frozen_string_literal: true

describe CSVImport::Operation do
  describe '#on_failure' do
    let(:operation) { described_class.new }
    let(:failure) { { error: :generic_error } }

    context 'when i18n translation is available' do
      before do
        I18n.backend.store_translations :en, operations: {
          csv_import: {
            operation: {
              failures: {
                generic_error: 'Error',
                unexpected_error: 'Unexpected error: %{exception_message}',
                missing_keys: 'Missing the following keys, %{keys}'
              }
            }
          }
        }

        operation.on_failure(failure)
      end

      after do
        I18n.backend.reload!
      end

      context 'when translation does not include additional attributes' do
        let(:failure) { { error: :error } }

        it 'adds in expected message' do
          expect(failure[:message]).to eql 'Error'
        end
      end

      context 'when translation includes additional attributes' do
        let(:failure) { { error: :missing_keys, keys: 'first_name, last_name' } }

        it 'adds in expected message' do
          expect(failure[:message]).to eql 'Missing the following keys, first_name, last_name'
        end
      end

      context 'when translation includes exception message' do
        let(:failure) { { error: :unexpected_error, exception: StandardError.new('Random Issue') } }

        it 'adds in expected message' do
          expect(failure[:message]).to eql 'Unexpected error: Random Issue'
        end
      end
    end

    context 'when i18n translation is not present' do
      before do
        operation.on_failure(failure)
      end

      it 'adds in default message' do
        expect(failure[:message]).to eql 'Generic error'
      end
    end
  end
end
