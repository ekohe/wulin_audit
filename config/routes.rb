Rails.application.routes.draw do
  namespace :wulin_audit do
    resources :audit_logs
    resources :record_audits
    resources :action_logs
    resources :action_log_analysis, only: :index
  end
end
