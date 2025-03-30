# frozen_string_literal: true

# Used to validate an MMS ID in a multivalued field
class MMSIDValidator < ActiveModel::Validator
  EXAMPLE_VALID_MMS_ID = '991234563681'
  MMS_ID_VALIDITY_REGEX = /99.*?3681/

  # @param record [ItemChangeSet::DescriptiveMetadataChangeSet]
  def validate(record)
    field = options[:attributes].first

    record.send(field).each do |n|
      next if MMS_ID_VALIDITY_REGEX.match?(n.value)

      record.errors.add field, "includes an MMS ID in the incorrect format (#{n.value})"
      break
    end
  end
end
