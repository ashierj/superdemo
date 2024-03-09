# frozen_string_literal: true

class Groups::Analytics::CycleAnalytics::ValueStreamsController < Groups::Analytics::ApplicationController
  include ::Analytics::CycleAnalytics::ValueStreamActions

  respond_to :json

  before_action :load_stage_events, only: %i[new edit]
  before_action :value_stream, only: %i[show edit update]

  before_action do
    push_frontend_feature_flag(:vsa_standalone_settings_page, namespace)
  end

  layout 'group'

  def new
    all_data_attributes = Gitlab::Analytics::CycleAnalytics::RequestParams.new(
      namespace: namespace,
      current_user: current_user
    ).to_data_attributes

    @data_attributes = all_data_attributes.slice(:default_stages, :namespace).merge(
      vsa_path: group_analytics_cycle_analytics_path(namespace)
    )
  end

  def edit
    all_data_attributes = Gitlab::Analytics::CycleAnalytics::RequestParams.new(
      namespace: namespace,
      value_stream: value_stream,
      current_user: current_user
    ).to_data_attributes

    @data_attributes = all_data_attributes.slice(
      :value_stream,
      :default_stages,
      :namespace
    ).merge(
      vsa_path: group_analytics_cycle_analytics_path(namespace),
      is_edit_page: true.to_s
    )
  end

  private

  def namespace
    @group
  end
end
