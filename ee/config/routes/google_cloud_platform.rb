# frozen_string_literal: true

namespace :google_cloud_platform do
  resources :artifact_registry, only: :index
end
