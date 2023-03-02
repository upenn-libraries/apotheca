# frozen_string_literal: true

module ImportService
  # Object containing asset location, metadata and structure.
  class AssetsData
    attr_reader :errors, :data, :location

    # Asset information can be provided in different structures. Filenames and asset metadata can be
    # provided in two ways:
    #   1. { arranged: [ { filename: 'file1.tif', label: '1' }, { filename: 'file2.tif', label: '2' }],
    #        unarranged: [ { filename: 'reference_shot.tif' }] }
    #   2. { arranged_filenames: ['file1.tif;file2.tif'], unarranged_filenames: 'reference_shot.tif' }
    #
    # File locations can be provided via :storage and :path keys:
    #   { storage: 'sceti-completed-n', path: 'object_3' }
    def initialize(**args)
      @data = args.deep_symbolize_keys.compact_blank # Store raw asset data provided.
      @location = AssetsLocation.new(**args)

      @errors = []
    end

    # Validate raw asset data provided.
    def valid?
      # Can't provide arranged/unarranged keys with arranged_filename/unarranged_filename keys
      if (data[:arranged] || data[:unarranged]) && (data[:arranged_filenames] || data[:unarranged_filenames])
        @errors << 'arranged_filenames/unarranged_filenames cannot be used in conjunction with arranged/unarranged keys'
      end

      # Ensure all arranged/unarranged assets have a filename
      @errors << 'arranged assets missing filename(s)'   if data[:arranged].present? && data[:arranged].all? { |a| a.key?(:filename) }
      @errors << 'unarranged assets missing filename(s)' if data[:unarranged].present? && data[:unarranged].all? { |a| a.key?(:filename) }

      # Ensure at least one asset is defined
      unless [:arranged_filenames, :unarranged_filenames, :arranged, :unarragned].any? { |k| data.key?(k) }
        @errors << 'no assets defined'
      end

      @errors.concat(location.errors) unless location.valid?

      errors.empty?
    end

    def arranged
      @arranged ||= normalize_data_for(:arranged)
    end

    def unarranged
      @unarranged ||= normalize_data_for(:unarranged)
    end

    def file_for(filename)
      location.file_for(filename)
    end

    # Return any files that are not present in storage.
    def missing_files
      all_filenames = arranged.pluck(:original_filename) + unarranged.pluck(:original_filename)
      all_filenames - location.filenames
    end

    private

    def normalize_data_for(type)
      if data.key?(:"#{type}_filenames")
        filenames = data[:"#{type}_filenames"].dup
        filenames.blank? ? [] : filenames.split(';').map(&:strip).map { |f| { original_filename: f } }
      elsif data.key?(:"#{type}")
        data[:"#{type}"].deep_dup.map do |a| # TODO: Can I use tap?
          a[:original_filename] = a.delete(:filename)
          a
        end
      else
        []
      end
    end
  end
end
