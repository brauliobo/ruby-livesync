module LiveSync
  module DSL

    extend ActiveSupport::Concern

    included do

      class_attribute :ctx

      class_attribute :attrs
      self.attrs = []

      def self.dsl attr, default: nil, enum: nil, type: nil, &block
        self.attrs << attr

        define_method attr do |sv=nil, &ablock|
          v   = instance_variable_get "@#{attr}"
          v ||= if block
            then instance_exec sv || default.dup, ablock, &block
            else sv || default.dup end
          instance_variable_set "@#{attr}", v if v
          return v if sv.nil? # getter

          # setter validation
          raise "#{ctx}/#{attr}: incorrect type of #{v.inspect}" if type and !v.is_a? type
          raise "#{ctx}/#{attr}: value not one of following #{enum}" if enum and !v.in? enum

          v
        end
      end

      def dsl_apply &block
        if b = binding and bs = block.source.match(/do(.+)end$/m)&.captures&.first
          b.eval bs, $config
          attrs.each do |a|
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
