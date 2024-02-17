# frozen_string_literal: true

module FeatureGate
  extend ActiveSupport::Concern

  class_methods do
    def actor_from_id(model_id)
      ::Feature::ActorWrapper.new(self, model_id)
    end
  end

  def flipper_id
    return if new_record?

    "#{self.class.name}:#{id}"
  end
end
