Rails.application.routes.draw do
  namespace :wulin_audit do
    resources :audit_logs do
      collection do
        get :translations
      end
    end
    resources :record_audits
  end
end