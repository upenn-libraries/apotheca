# frozen_string_literal: true

module Steps
  class VirusCheck
    include Dry::Monads[:result]

    def call(**attributes)
      file = attributes[:file] || attributes['file']
      binding.b
      if file.present? && file.size <= 2.gigabytes

        result = scan_for_viruses(file.path)
        if result
          success = AssetResource::PreservationEvent.virus_check outcome: Premis::Outcomes::SUCCESS.uri,
                                                                 note: I18n.t('preservation_events.virus_check.success.note'),
                                                                 implementer: attributes[:updated_by]
          attributes[:temporary_events] = [success]
          Success(attributes)
        else
          failure = AssetResource::PreservationEvent.virus_check outcome: Premis::Outcomes::FAILURE.uri,
                                                                 note: I18n.t('preservation_events.virus_check.failure.note'),
                                                                 implementer: attributes[:updated_by]
          attributes[:temporary_events] = [failure]
          Failure(error: :virus_detected)
        end
      end
    end

    private

    def scan_for_viruses(path)
      scan_result = Clamby.safe?(path)
      if scan_result
        true
      else
        File.delete(path)
        false
      end
    end
  end
end
