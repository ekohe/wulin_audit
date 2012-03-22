module MongoidSupport
  extend ActiveSupport::Concern

  module ClassMethods

    def table_name
      collection_name
    end

    def reflections
      relations
    end

    def order(*args)
      if args.size == 1 and args.first.is_a?(String) and args.first =~ /^(.*)\s(DESC|ASC)$/
        orders = []
        order_column, order = $1, $2
        order_column = order_column.split('.')[1] if order_column.include?('.')
        orders << [order_column.to_sym, order.downcase.to_sym]
        args[0] = orders
      end
      self.order_by(*args)
    end

    def columns
      fields.values
    end

    def column_names
      fields.keys
    end

  end

end

# Overrides on Mongoid
module Mongoid #:nodoc:

  module Criterion #:nodoc:
    module Inclusion
      alias_method :old_where, :where
      def where(selector = nil)
        if selector.class==String && (selector =~ /UPPER\(.*?\.([^)]*)\) LIKE UPPER\('([^%]*)%'\)/)
          # selector.match like_regexp
          selector = {$1 => Regexp.new("#{Regexp.escape($2)}.*", true)}
        end

        old_where(selector)
      end
    end

    # TODO: Improve order function
    module Optional
      alias_method :old_order, :order
      def order(*args)
        if args.size == 1 and args.first.is_a?(String) and args.first =~ /^(.*)\s(DESC|ASC)$/
          orders = []
          order_column, order = $1, $2
          order_column = order_column.split('.')[1] if order_column.include?('.')
          orders << [order_column.to_sym, order.downcase.to_sym]
          args[0] = orders
        end
        old_order(*args)
      end
    end
  end

  # Override the +method_missing+ method of +Mongoid::Attributes+
  # Return nil instead of raise error
  module Attributes
    alias_method :old_method_missing, :method_missing
    def method_missing(name, *args)
      old_method_missing(name, *args)
    rescue
      nil
    end
  end

end
