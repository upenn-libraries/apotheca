# frozen_string_literal: true

RSpec.describe AlertMessage, type: :model do
  context 'when using basic attributes' do
    let(:alert_message) { create(:alert_message) }

    it 'has an active boolean that defaults to false' do
      expect(alert_message.active?).to be false
    end

    it 'has a location' do
      expect(alert_message.location).to be_in AlertMessage::LOCATIONS
    end

    it 'has a level' do
      expect(alert_message.level).to be_in AlertMessage::LEVELS
    end
  end

  context 'with validation errors' do
    let(:alert_message) { create(:alert_message, message: '') }

    it 'raises an error if a message is set to active without message content' do
      alert_message.active = true
      expect(alert_message.valid?).to be false
      expect(alert_message.errors.first.attribute).to eq :message
    end

    it 'raises an error message if location is set to an invalid value' do
      alert_message.location = 'footer'
      expect(alert_message.valid?).to be false
      expect(alert_message.errors.first.attribute).to eq :location
    end

    it 'raises an error message if level is set to an invalid value' do
      alert_message.level = 'armageddon'
      expect(alert_message.valid?).to be false
      expect(alert_message.errors.first.attribute).to eq :level
    end

    it 'does not raise and error if level is not provided' do
      alert_message.level = nil
      expect(alert_message.valid?).to be true
    end
  end
end
