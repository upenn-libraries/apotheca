# frozen_string_literal: true

# Custom processor for extracting text from a HexaPDF page's content stream.
# HexaPDF interprets content stream operators like 'Tj' (show text) internally,
# and then invokes any corresponding instance methods for further processing using meta-programming.
# @example
#   processor = ExtractPDFText.new
#   page.process_contents(processor)
#   expect(processor.text).to include('hello')
class ExtractPDFText < HexaPDF::Content::Processor
  def initialize(resources = nil)
    super
    @parts = []
  end

  # Extract text any time 'show text' operator runs during PDF processing
  #
  # The inherited #process method will automatically invoke this method after the 'Tj' (show text) PDF operator runs,
  # behaving as a kind of post-processing hook. We define it here to extract and store decoded text content for testing.
  # @see HexaPDF::Content::Processor#process
  # @see HexaPDF::Type::Page#process_contents
  # @see https://hexapdf.gettalong.org/examples/show_char_bboxes.html for a more complex example of hooking into the
  # processing flow to manipulate the page itself.
  def show_text(str)
    @parts << decode_text(str)
  end

  # Expose the text for testing
  def text
    @parts.join
  end

  alias show_text_with_positioning show_text
end
