# frozen_string_literal: true

describe Operation do
  describe '#on_failure' do
    let(:failure) { { error: :generic_error } }

    let(:operation) do
      baking_operation = stub_const('Baking::Operation', Class.new(::Operation))
      banana_bread_operation = stub_const('Baking::BananaBread::Operation', Class.new(baking_operation))
      banana_bread_operation.new
    end

    context 'when i18n translation is available' do
      before do
        I18n.backend.store_translations :en, operations: {
          baking: {
            failure: {
              oven_power: 'Oven won\'t turn on'
            },
            banana_bread: {
              failure: {
                generic_error: 'Error',
                unexpected_error: 'Unexpected error: %{exception_message}',
                missing_ingredients: 'Missing the following ingredients, %{ingredients}'
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
        let(:failure) { { error: :missing_ingredients, ingredients: 'bananas, flour' } }

        it 'adds in expected message' do
          expect(failure[:message]).to eql 'Missing the following ingredients, bananas, flour'
        end
      end

      context 'when translation includes exception message' do
        let(:failure) { { error: :unexpected_error, exception: StandardError.new('Stuck to pan') } }

        it 'adds in expected message' do
          expect(failure[:message]).to eql 'Unexpected error: Stuck to pan'
        end
      end

      context 'when translation provided provided via superclass' do
        let(:failure) { { error: :oven_power } }

        it 'adds in expected message' do
          expect(failure[:message]).to eql 'Oven won\'t turn on'
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
