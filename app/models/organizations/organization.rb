# frozen_string_literal: true

module Organizations
  class Organization < ApplicationRecord
    DEFAULT_ORGANIZATION_ID = 1

    scope :without_default, -> { where.not(id: DEFAULT_ORGANIZATION_ID) }

    before_destroy :check_if_default_organization

    has_many :namespaces
    has_many :groups

    validates :name,
      presence: true,
      length: { maximum: 255 }

    validates :path,
      presence: true,
      length: { minimum: 2, maximum: 255 }

    def default?
      id == DEFAULT_ORGANIZATION_ID
    end

    private

    def check_if_default_organization
      return unless default?

      raise ActiveRecord::RecordNotDestroyed, _('Cannot delete the default organization')
    end
  end
end
