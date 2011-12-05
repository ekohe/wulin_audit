Rails.application.routes.draw do
  namespace :wulin_audit do
    resources :audit_logs
  end
end