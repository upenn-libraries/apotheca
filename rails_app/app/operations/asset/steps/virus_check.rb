# frozen_string_literal: true

module Asset
  module Steps
    # Step to scan a given file for viruses using Clamby/Clamscan
    class VirusCheck
      include Dry::Monads[:result]

      # Perform a virus scan using Clamby. There are 5 potential outcomes:
      # 1. File is too big and can't be scanned by Clam.
      # 2. File is scanned and no virus found.
      # 3. File is scanned and a virus is found. File is deleted from the local system and failure is returned.
      # 4. Problem using Clamby. Failure is returned and Honeybadger notification is sent.
      # 5. Check is skipped due to configuration setting
      #
      # @param change_set [AssetChangeSet]
      # @param file [ActionDispatch::Http::UploadedFile, ImportService::S3Storage::File, nil]
      def call(change_set, file = nil)
        return Success(change_set) if skip_in_environment? || file.blank?

        if should_scan_file?(file)
          case Clamby.safe?(file.path)
          when TrueClass
            change_set.temporary_events = [AssetResource::PreservationEvent.virus_check(
              outcome: Premis::Outcomes::SUCCESS.uri, implementer: change_set.updated_by,
              note: I18n.t('preservation_events.virus_check.clean')
            )]
            Success(change_set)
          when FalseClass
            File.delete(file.path)
            Failure(error: :virus_detected)
          else
            report_clamscan_problem(file.path)
            Failure(error: :clamscan_problem)
          end
        else
          change_set.temporary_events = [AssetResource::PreservationEvent.virus_check(
            outcome: Premis::Outcomes::WARNING.uri, note: I18n.t('preservation_events.virus_check.unscanned'),
            implementer: change_set.updated_by
          )]
          Success(change_set)
        end
      end

      private

      # Returns true if file is present and it is under 2 GB
      # @param file [String]
      # @return [Boolean]
      def should_scan_file?(file)
        file.size <= Settings.virus_check.size_threshold
      end

      # @return [Boolean, nil]
      def skip_in_environment?
        Settings.virus_check.skip
      end

      # Clamby calls return nil if there is a problem finding the file or using clamscan
      # @param path [String]
      def report_clamscan_problem(path)
        Honeybadger.notify("Problem scanning file (#{path}) using clamscan.")
      end
    end
  end
end
