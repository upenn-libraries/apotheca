# frozen_string_literal: true

# Factory for AssetResource::PreservationEventResources.
FactoryBot.define do
  factory :preservation_event, class: AssetResource::PreservationEvent do
    timestamp { DateTime.current }
    agent_type { 'local' }

    trait :success do
      outcome { Premis::Outcomes::SUCCESS.uri }
    end

    trait :failure do
      outcome { Premis::Outcomes::FAILURE.uri }
    end

    trait :warning do
      outcome { Premis::Outcomes::WARNING.uri }
    end

    trait :virus_check do
      event_type { Premis::Events::VIRUS_CHECK.uri }
    end

    trait :ingestion do
      event_type { Premis::Events::INGEST.uri }
    end

    trait :filename_changed do
      event_type { Premis::Events::EDIT_FILENAME.uri }
    end

    trait :checksum do
      event_type { Premis::Events::CHECKSUM.uri }
    end

    trait :system_agent do
      agent { 'system@agent.com' }
      agent_role { Premis::Roles::PROGRAM.uri }
    end

    trait :user_agent do
      agent { Faker::Internet.email }
      agent_role { Premis::Roles::IMPLEMENTER.uri }
    end
  end
end
