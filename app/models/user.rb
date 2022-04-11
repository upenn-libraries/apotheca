# frozen_string_literal: true

# this is a User
class User < ApplicationRecord
  ADMIN_ROLE = 'admin'
  EDITOR_ROLE = 'editor'
  READONLY_ROLE = 'readonly'
  ROLES = [ADMIN_ROLE, EDITOR_ROLE, READONLY_ROLE].freeze

  devise :rememberable, :timeoutable
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: []
  end

  validate :require_only_one_role
  validates :roles, inclusion: ROLES
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

  # @return [TrueClass, FalseClass]
  def admin?
    roles.include? ADMIN_ROLE
  end

  # @return [TrueClass, FalseClass]
  def editor?
    roles.include? EDITOR_ROLE
  end

  # @return [TrueClass, FalseClass]
  def readonly?
    roles.include? READONLY_ROLE
  end

  private

  def require_only_one_role
    if roles.length > 1
      errors.add(:roles, 'Invalid attempt to set more than one role on a User')
    elsif roles.empty?
      errors.add(:roles, 'One role must be set for a User')
    end
  end
end
