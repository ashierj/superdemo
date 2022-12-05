# frozen_string_literal: true

class Admin::BroadcastMessagesController < Admin::ApplicationController
  include BroadcastMessagesHelper

  before_action :find_broadcast_message, only: [:edit, :update, :destroy]
  before_action :find_broadcast_messages, only: [:index, :create]
  before_action :push_features, only: [:index, :edit]

  feature_category :onboarding
  urgency :low

  def index
    @broadcast_message = BroadcastMessage.new
  end

  def edit
  end

  def create
    @broadcast_message = BroadcastMessage.new(broadcast_message_params)
    success = @broadcast_message.save

    respond_to do |format|
      format.json do
        if success
          render json: @broadcast_message, status: :ok
        else
          render json: { errors: @broadcast_message.errors.full_messages }, status: :bad_request
        end
      end
      format.html do
        if success
          redirect_to admin_broadcast_messages_path, notice: _('Broadcast Message was successfully created.')
        else
          render :index
        end
      end
    end
  end

  def update
    success = @broadcast_message.update(broadcast_message_params)

    respond_to do |format|
      format.json do
        if success
          render json: @broadcast_message, status: :ok
        else
          render json: { errors: @broadcast_message.errors.full_messages }, status: :bad_request
        end
      end
      format.html do
        if success
          redirect_to admin_broadcast_messages_path, notice: _('Broadcast Message was successfully updated.')
        else
          render :edit
        end
      end
    end
  end

  def destroy
    @broadcast_message.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(default: { action: 'index' }) }
      format.js { head :ok }
    end
  end

  def preview
    @broadcast_message = BroadcastMessage.new(broadcast_message_params)
    render partial: 'admin/broadcast_messages/preview'
  end

  protected

  def find_broadcast_message
    @broadcast_message = BroadcastMessage.find(params[:id])
  end

  def find_broadcast_messages
    @broadcast_messages = BroadcastMessage.order(ends_at: :desc).page(params[:page]) # rubocop: disable CodeReuse/ActiveRecord
  end

  def broadcast_message_params
    params.require(:broadcast_message)
      .permit(%i[
                theme
                ends_at
                message
                starts_at
                target_path
                broadcast_type
                dismissable
              ], target_access_levels: []).reverse_merge!(target_access_levels: [])
  end

  def push_features
    push_frontend_feature_flag(:vue_broadcast_messages, current_user)
    push_frontend_feature_flag(:role_targeted_broadcast_messages, current_user)
  end
end
