module Crm; module Core; module Mixins
  # +Searchable+ provides several methods related to searching.
  # @api public
  module Searchable
    extend ActiveSupport::Concern

    # @api public
    module ClassMethods
      # Returns the item of this base type that was created first.
      # @return [BasicResource]
      # @api public
      def first
        search_configurator.
            sort_by('created_at').
            limit(1).
            perform_search.
            first
      end

      # Returns an {Crm::Core::ItemEnumerator enumerator} for iterating over all items
      # of this base type. The items are sorted by +created_at+.
      # @return [ItemEnumerator]
      # @api public
      def all
        search_configurator.
            sort_by('created_at').
            unlimited.
            perform_search
      end

      # Returns a new {Crm::Core::SearchConfigurator SearchConfigurator} set to the given
      # filter (+field+, +condition+, +value+). Additionally, it is limited
      # to this base type and can be further refined using chainable methods.
      # This method is equivalent to +search_configurator.and(field, condition, value)+.
      # See {SearchConfigurator#and} for parameters and examples.
      # @return [SearchConfigurator]
      # @api public
      def where(field, condition, value = nil)
        search_configurator.and(field, condition, value)
      end

      # Returns a new {Crm::Core::SearchConfigurator SearchConfigurator} set to the given
      # negated filter (+field+, +condition+, +value+). Additionally, it is limited
      # to this base type and can be further refined using chainable methods.
      # This method is equivalent to +search_configurator.and_not(field, condition, value)+.
      # See {SearchConfigurator#and_not} for parameters and examples.
      # @return [SearchConfigurator]
      # @api public
      def where_not(field, condition, value = nil)
        search_configurator.and_not(field, condition, value)
      end

      # Returns a new {Crm::Core::SearchConfigurator SearchConfigurator} set to the given
      # +query+. Additionally, it is limited
      # to this base type and can be further refined using chainable methods.
      # This method is equivalent to +search_configurator.query(query)+.
      # See {SearchConfigurator#query} for examples.
      # @return [SearchConfigurator]
      # @api public
      def query(query)
        search_configurator.query(query)
      end

      # Returns a new {Crm::Core::SearchConfigurator SearchConfigurator} limited
      # to this base type. It can be further refined using chainable methods.
      # @return [SearchConfigurator]
      # @api public
      def search_configurator
        SearchConfigurator.new({
          filters: filters_for_base_type,
        })
      end

      private

      def filters_for_base_type
        [{
          field: 'base_type',
          condition: 'equals',
          value: base_type,
        }]
      end
    end
    # @!parse extend ClassMethods
  end
end; end; end
