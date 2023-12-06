# frozen_string_literal: true

module EE
  module PackagesHelper
    extend ::Gitlab::Utils::Override

    override :settings_data
    def settings_data(project)
      super.merge(
        show_dependency_proxy_settings: show_dependency_proxy_settings?(project).to_s
      )
    end

    private

    def show_dependency_proxy_settings?(project)
      ::Feature.enabled?(:packages_dependency_proxy_maven, project) &&
        Ability.allowed?(current_user, :admin_dependency_proxy_packages_settings,
          project.dependency_proxy_packages_setting)
    end
  end
end
