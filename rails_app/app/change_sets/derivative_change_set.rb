# frozen_string_literal: true

# ChangeSet for Derivatives
class DerivativeChangeSet < ChangeSet
  property :file_id, multiple: false
  property :mime_type, multiple: false
  property :type, multiple: false
  property :generated_at, multiple: false
  property :stale, multiple: false, required: false, default: false

  validates :file_id, :mime_type, :type, :generated_at, presence: true
end
