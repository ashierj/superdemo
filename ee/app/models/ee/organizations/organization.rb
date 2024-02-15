# frozen_string_literal: true

module EE
  module Organizations
    module Organization
      extend ActiveSupport::Concern

      prepended do
        has_many :sbom_occurrences, through: :projects, class_name: 'Sbom::Occurrence'
      end
    end
  end
end
