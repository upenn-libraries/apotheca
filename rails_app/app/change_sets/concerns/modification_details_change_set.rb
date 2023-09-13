# frozen_string_literal: true

# ChangeSet for the ModificationDetails nested resource
module ModificationDetailsChangeSet
  extend ActiveSupport::Concern

  included do
    property :first_created_at, multiple: false, required: false
    property :created_by, multiple: false, required: true
    property :updated_by, multiple: false, required: true

    validates :created_by, :updated_by, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP } # Validate emails
  end
end
