# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end

  trait :viewer do
    roles { [User::VIEWER_ROLE] }
  end

  trait :editor do
    roles { [User::EDITOR_ROLE] }
  end

  trait :admin do
    roles { [User::ADMIN_ROLE] }
  end
end
