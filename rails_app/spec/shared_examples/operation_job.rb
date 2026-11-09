# frozen_string_literal: true

shared_examples_for 'OperationJob' do
  let(:job) { described_class.new }

  before do
    raise 'arguments must be set with `let(:args)`' unless defined? args
  end

  describe '#operation' do
    it 'implements #operation method' do
      expect(job).to respond_to(:operation)
    end

    it 'returns a Result object' do
      expect(job.operation(*args)).to be_a Dry::Monads::Result
    end
  end

  describe '#perform' do
    context 'when operation returns a failure' do
      context 'with an error message only' do
        before do
          allow(job).to receive(:operation).with(*args)
                                           .and_return(Dry::Monads::Failure.new(error: :oh_no_something_bad_happened))
        end

        it 'raises an exception' do
          expect { job.perform(*args) }.to raise_error OperationJob::Error, 'Oh No Something Bad Happened'
        end
      end

      context 'with an exception' do
        let(:exception) do
          Valkyrie::Persistence::StaleObjectError.new('The object has been updated by another process.')
        end

        before do
          allow(job).to receive(:operation).with(*args)
                                           .and_return(Dry::Monads::Failure.new(error: :error, exception: exception))
        end

        it 'raises an exception' do
          expect { job.perform(*args) }.to raise_error exception
        end
      end
    end
  end
end
