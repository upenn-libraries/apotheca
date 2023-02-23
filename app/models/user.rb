# frozen_string_literal: true

# this is a User
class User < ApplicationRecord
  ADMIN_ROLE = 'admin'
  EDITOR_ROLE = 'editor'
  VIEWER_ROLE = 'viewer'
  ROLES = [ADMIN_ROLE, EDITOR_ROLE, VIEWER_ROLE].freeze

  devise :rememberable, :timeoutable
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: []
  end

  has_many :bulk_exports, foreign_key: 'created_by_id', dependent: :destroy
  has_many :bulk_imports, foreign_key: 'created_by_id', dependent: :destroy

  before_validation :deduplicate_roles

  validate :require_only_one_role
  validates :roles, inclusion: ROLES
  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }, if: :provider_provided?

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :active_filter, ->(query) { where(active: query) }
  scope :roles_filter, ->(query) { where('? = ANY (roles)', query.downcase) }
  scope :users_search, ->(query) { where("email || ' ' || first_name || ' ' || last_name ILIKE ?", "%#{query}%") }
  scope :with_exports, -> { joins(:bulk_exports).distinct }

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid, active: true).first_or_create do |user|
      user.email = auth.info.email
      user.first_name = 'A.'
      user.last_name = 'Developer'
      user.active = true
      user.roles << 'admin'
    end
  end

  # @return [String (frozen)]
  def full_name
    "#{first_name} #{last_name}"
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
