# frozen_string_literal: true

module Steps
  # Step to scan a given file for viruses using Clamby/Clamscan
  class VirusCheck
    include Dry::Monads[:result]

    # Perform a virus scan using Clamby. There are 4 potential outcomes:
    # 1. File is too big and can't be scanned by Clam.
    # 2. File is scanned and no virus found.
    # 3. File is scanned and a virus is found. File is deleted from the local system and failure is returned.
    # 4. Problem using Clamby. Failure is returned and Honeybadger notification is sent.
    def call(**attributes)
      file = attributes[:file] || attributes['file']
      if skip_scan?(file)
        attributes[:temporary_events] = AssetResource::PreservationEvent.virus_check(
          outcome: Premis::Outcomes::SUCCESS.uri, note: I18n.t('preservation_events.virus_check.unscanned'),
          implementer: attributes[:updated_by]
        )
        Success(attributes)
      else
        case Clamby.safe?(file.path)
        when TrueClass
          attributes[:temporary_events] = AssetResource::PreservationEvent.virus_check(
            outcome: Premis::Outcomes::SUCCESS.uri, implementer: attributes[:updated_by],
            note: I18n.t('preservation_events.virus_check.clean')
          )
          Success(attributes)
        when FalseClass
          File.delete(file.path)
          Failure(error: :virus_detected)
        else
          report_clamscan_problem(file.path)
          Failure(error: :clamscan_problem)
        end
      end
    end

    private

    # Skip the scan if no file is present or if it is over 2 GB
    # @param [String] file
    # @return [Boolean]
    def skip_scan?(file)
      return true if file.blank?

      file.present? && file.size >= 2.gigabytes
    end

    # Clamby calls return nil if there is a problem finding the file or using clamscan
    # @param [String] path
    def report_clamscan_problem(path)
      Honeybadger.notify("Problem scanning file (#{path}) using clamscan.")
    end
  end
end
