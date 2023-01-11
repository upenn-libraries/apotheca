# frozen_string_literal: true

require_relative 'concerns/queueable'

describe Import do
  it_behaves_like 'queueable'
end
