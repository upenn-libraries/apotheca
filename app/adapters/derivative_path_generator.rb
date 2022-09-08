class DerivativePathGenerator
  def initialize(base_path: nil)
    @base_path = base_path
  end

  def generate(resource:, file:, original_filename:)
    raise ArgumentError, "original_filename must be provided" unless original_filename
    "#{resource.id.to_s}/#{original_filename}"
  end
end