module LiveSync
  module DSL

    extend ActiveSupport::Concern

    included do

      class_attribute :ctx

      class_attribute :attrs
      self.attrs = []

      def self.dsl attr, default: nil, enum: nil, type: nil, &block
        self.attrs << attr
        define_method attr do |sv=nil|
          v = instance_variable_get("@#{attr}") and return(if v.nil? then default else v end) if sv.nil?

          raise "#{ctx}/#{attr}: incorrect type" if type and !sv.is_a? type
          raise "#{ctx}/#{attr}: value not one of following #{enum}" if enum and !sv.in? enum

          instance_variable_set "@#{attr}", sv
          instance_exec sv, &block if block
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
