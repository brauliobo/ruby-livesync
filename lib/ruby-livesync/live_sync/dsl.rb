module LiveSync
  module DSL

    extend ActiveSupport::Concern

    included do

      class_attribute :ctx

      class_attribute :attrs
      self.attrs = []

      def self.dsl attr, default: nil, type: nil, &block
        self.attrs << attr
        define_method attr do |value=nil|
          return instance_variable_get("@#{attr}") || default unless value
          raise "#{ctx}: incorrect type for `#{attr}`" if type and !value.is_a? type
          instance_exec value, &block if block
          instance_variable_set "@#{attr}", value
        end
      end

      def dsl_apply &block
        if b = binding and bs = block.source.match(/do(.+)end$/m)&.captures&.first
          b.eval bs
          attrs.each do |a| # read local variables
            next unless a.in? b.local_variables
            send a, b.local_variable_get(a)
          end
        else
          instance_exec &block
        end
      end

    end

  end
end
