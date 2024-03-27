# frozen_string_literal: true

FactoryBot.define do
  factory :project_security_setting do
    project { association :project, security_setting: instance }
    auto_fix_container_scanning { true }
    auto_fix_dast { true }
    auto_fix_dependency_scanning { true }
    auto_fix_sast { true }
    continuous_vulnerability_scans_enabled { false }
    container_scanning_for_registry_enabled { false }
    pre_receive_secret_detection_enabled { false }

    trait :disabled_auto_fix do
      auto_fix_container_scanning { false }
      auto_fix_dast { false }
      auto_fix_dependency_scanning { false }
      auto_fix_sast { false }
    end
  end
end
