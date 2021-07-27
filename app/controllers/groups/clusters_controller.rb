# frozen_string_literal: true

class Groups::ClustersController < Clusters::ClustersController
  include ControllerWithCrossProjectAccessCheck

  prepend_before_action :group
  requires_cross_project_access

  layout 'group'

  private

  def clusterable
    @clusterable ||= ClusterablePresenter.fabricate(group, current_user: current_user)
  end

  def group
    @group ||= find_routable!(Group, params[:group_id] || params[:id], request.path_info)
  end

  def metrics_dashboard_params
    {
      cluster: cluster,
      cluster_type: :group,
      group: group
    }
  end
end
