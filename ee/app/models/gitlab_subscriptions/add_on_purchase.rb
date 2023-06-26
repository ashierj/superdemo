# frozen_string_literal: true

module GitlabSubscriptions
  class AddOnPurchase < ApplicationRecord
    belongs_to :add_on, foreign_key: :subscription_add_on_id, inverse_of: :add_on_purchases
    belongs_to :namespace

    has_many :assigned_users, class_name: 'GitlabSubscriptions::UserAddOnAssignment', inverse_of: :add_on_purchase

    validates :add_on, :namespace, :expires_on, presence: true
    validates :subscription_add_on_id, uniqueness: { scope: :namespace_id }
    validates :quantity,
      presence: true,
      numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :purchase_xid,
      presence: true,
      length: { maximum: 255 }
  end
end
