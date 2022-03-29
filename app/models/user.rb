# frozen_string_literal: true

# this is a User
class User < ApplicationRecord
  devise :rememberable, :timeoutable
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: []
  end

  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }


  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid, active: true).first_or_create do |user|
      user.email = auth.info.email
      user.first_name = 'A.'
      user.last_name = 'Developer'
      user.active = true
    end
  end
end
