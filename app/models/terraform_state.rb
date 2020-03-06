# frozen_string_literal: true

class TerraformState < ApplicationRecord
  belongs_to :project

  validates :project_id, presence: true

  mount_uploader :file, TerraformStateUploader
end
