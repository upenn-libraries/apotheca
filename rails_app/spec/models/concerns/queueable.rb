# frozen_string_literal: true

shared_examples_for 'queueable' do
  let(:queueable_obj) { described_class.new }

  context 'when queued' do
    it 'can transition to cancelled' do
      expect(queueable_obj).to transition_from(:queued).to(:cancelled).on_event(:cancel)
    end

    it 'can transition to processing' do
      expect(queueable_obj).to transition_from(:queued).to(:processing).on_event(:process)
    end
  end

  context 'when processing' do
    before { queueable_obj.process }

    it 'cannot transition to cancelled' do
      expect(queueable_obj).not_to allow_event(:cancel)
    end

    it 'can transition to successful' do
      expect(queueable_obj).to allow_event(:success)
    end

    it 'can transition to failure' do
      expect(queueable_obj).to allow_event(:failure)
    end
  end

  it 'implements #run method' do
    expect(queueable_obj).to respond_to(:run)
  end

  it 'requires state' do
    queueable_obj.state = nil
    expect(queueable_obj.save).to be_falsey
  end
end
