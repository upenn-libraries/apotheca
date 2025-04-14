# frozen_string_literal: true

require 'rspec/expectations'

# Custom matcher to test if a HexaPDF::Type::Page has expected text content
RSpec::Matchers.define :have_pdf_text do |expected_text|
  match do |page|
    processor = ExtractPDFText.new
    page.process_contents(processor)
    actual_text = processor.text
    actual_text.include?(expected_text)
  end

  failure_message do |page|
    processor = ExtractPDFText.new
    page.process_contents(processor)
    actual_text = processor.text
    "expected that '#{actual_text}'' would include '#{expected_text}'"
  end

  failure_message_when_negated do |page|
    processor = ExtractPDFText.new
    page.process_contents(processor)
    actual_text = processor.text
    "expected that '#{actual_text}' would not include '#{expected_text}'"
  end
end
