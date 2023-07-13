# frozen_string_literal: true

class ItemChangeSet
  # ChangeSet for ItemResource::DescriptiveMetadata nested resource.
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::Fields::CONFIG.each do |field, type|
      klass = "ItemResource::DescriptiveMetadata::#{type.to_s.titlecase}Field".constantize

      property field, multiple: true, required: false, type: Valkyrie::Types::Array(klass), default: []

      # Remove blank values from array.
      define_method "#{field}=" do |values|
        super(compact_value(values))
      end

      validates field, each_object: { required: [:value] }
    end

    validate :validate_roles # Validating that each :role included with a :name contains a :value
    validates :title, length: { minimum: 1, message: 'can\'t be blank' }, if: ->(metadata) { metadata.bibnumber.blank? }

    def validate_roles
      errors.add(:name, 'role missing value') unless name.map(&:role).flatten.all? { |r| r[:value].present? }
    end

    def compact_value(value)
      if value.is_a? Array
        value.map { |v| compact_value(v) }.compact_blank
      elsif value.is_a? Hash
        value.transform_values! { |v| compact_value(v) }.compact_blank
      else
        value
      end
    end
  end
end
