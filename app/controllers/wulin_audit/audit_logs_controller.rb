# Here are request interfaces for stand alone
# Totailly belongs to WulinAudit::AuditLog resources
# implement user interface in here,and it can be customed
if defined? WulinMaster
  module WulinAudit
    class AuditLogsController < WulinMaster::ScreenController
      controller_for_screen AuditLogScreen
      
      # Returns field translations for a given model class
      def translations
        class_name = params[:class_name]
        translations = {}
        
        if class_name.present?
          begin
            # Convert class_name to model name format (e.g., "Order" stays "Order", "OrderLine" becomes "order_line")
            model_key = class_name.underscore.to_sym
            
            # Get translations from I18n
            if I18n.exists?("activerecord.attributes.#{model_key}")
              translations = I18n.t("activerecord.attributes.#{model_key}", default: {})
              # Convert all keys to strings
              translations = translations.stringify_keys if translations.is_a?(Hash)
            end
          rescue => e
            Rails.logger.error "Error loading translations for #{class_name}: #{e.message}"
          end
        end
        
        render json: translations
      end
    end
  end
end