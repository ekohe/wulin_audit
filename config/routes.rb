Rails.application.routes.draw do
  namespace :wulin_audit do
    resources :audit_logs
  end
  
  resources :audit_logs
  resources :record_audits
end