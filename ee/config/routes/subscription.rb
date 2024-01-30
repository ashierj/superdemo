# frozen_string_literal: true

resource :subscriptions, only: [:new, :create] do
  get :buy_minutes
  get :buy_storage
  get :payment_form
  get :payment_method
  post :validate_payment_method

  scope module: :subscriptions do
    resources :groups, only: [:edit, :update]
    resources :hand_raise_leads, only: :create
  end
end

scope module: :subscriptions do
  resources :trials, only: [:new, :create]

  namespace :trials do
    resource :duo_pro, only: [:new, :create]
  end
end
