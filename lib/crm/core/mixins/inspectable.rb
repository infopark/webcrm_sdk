module Crm; module Core; module Mixins
  module Inspectable
    extend ActiveSupport::Concern

    def inspect
      field_values = self.class.inspectable_fields.map do |field|
        value = self.send(field).inspect

        "#{field}=#{value}"
      end

      "#<#{self.class.name} #{field_values.join(', ')}>"
    end

    included do
      cattr_accessor :inspectable_fields

      self.inspectable_fields = []
    end

    module ClassMethods
      def inspectable(*fields)
        self.inspectable_fields = *fields
      end
    end
  end
end; end; end
