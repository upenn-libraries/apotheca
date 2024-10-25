# frozen_string_literal: true

# Generates path for replica (preservation-copy) files. For use with Valkyrie adapters.
#
# Replaces default Valkyrie::Storage::Shrine::IDPathGenerator, uses the same path as the Valkyrie file provided. The
# file provided must be a Valkyrie::StorageAdapter::File. The main purpose of this is to have the same name for the
# preservation file and the preservation-copy file.
class PreservationCopyPathGenerator
  def initialize(base_path: nil)
    @base_path = base_path
  end

  def generate(file:, **)
    unless file.present? && file.is_a?(Valkyrie::StorageAdapter::File)
      raise ArgumentError, 'file must be a Valkyrie::StorageAdapter::File'
    end

    # Extract the filename/filepath from the Valkyrie::ID
    file.id.id.split('://').last
  end
end
