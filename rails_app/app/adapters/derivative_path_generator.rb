# frozen_string_literal: true

# Generates paths for use with Valkyrie adapters.
#
# Replaces default Valkyrie::Storage::Shrine::IDPathGenerator, uses original_filename instead
# of random UUID for derivatives.
class DerivativePathGenerator
  def initialize(base_path: nil)
    @base_path = base_path
  end

  def generate(resource:, original_filename:, **)
    raise ArgumentError, 'original_filename must be provided' unless original_filename

    "#{resource.id}/#{original_filename}"
  end
end
