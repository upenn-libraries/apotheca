# frozen_string_literal: true

# this is a User
class User < ApplicationRecord
  ADMIN_ROLE = 'admin'
  EDITOR_ROLE = 'editor'
  VIEWER_ROLE = 'viewer'
  ROLES = [ADMIN_ROLE, EDITOR_ROLE, VIEWER_ROLE].freeze

  devise :rememberable, :timeoutable
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: [:developer, :saml]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  has_many :bulk_exports, foreign_key: 'created_by_id', dependent: :destroy, inverse_of: :created_by
  has_many :bulk_imports, foreign_key: 'created_by_id', dependent: :destroy, inverse_of: :created_by

  before_validation :deduplicate_roles

  validate :require_only_one_role
  validates :roles, inclusion: ROLES
  validates :email, uniqueness: { scope: :provider }, presence: true
  validates :uid, uniqueness: { scope: :provider }, presence: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :active_filter, ->(query) { where(active: query) }
  scope :roles_filter, ->(query) { where('? = ANY (roles)', query.downcase) }
  scope :users_search, ->(query) { where("email || ' ' || first_name || ' ' || last_name ILIKE ?", "%#{query}%") }
  scope :with_exports, -> { joins(:bulk_exports).distinct }
  scope :with_imports, -> { joins(:bulk_imports).distinct }

  def self.from_omniauth_saml(auth)
    where(provider: auth.provider, uid: auth.info.uid, active: true).first_or_create do |user|
      user.email = auth.info.email.presence || auth.info.uid
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.active = true
      user.roles << VIEWER_ROLE
    end
  end

  # @param [OmniAuth::AuthHash] auth
  # @return [User]
  def self.from_omniauth_developer(auth)
    return unless Rails.env.development?

    where(provider: auth.provider, uid: auth.uid, email: auth.info.email, active: true).first_or_create do |user|
      user.email = auth.info.email
      user.first_name = 'DEVELOPER'
      user.last_name = 'ACCOUNT'
      user.active = true
      user.roles << ADMIN_ROLE
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
  def viewer?
    roles.include? VIEWER_ROLE
  end

  private

  def deduplicate_roles
    roles.uniq!
  end

  def require_only_one_role
    if roles.length > 1
      errors.add(:roles, 'cannot be multivalued')
    elsif roles.empty?
      errors.add(:roles, 'must be set for a User')
    end
  end

  # @return [TrueClass, FalseClass]
  def provider_provided?
    provider.present?
  end
end
