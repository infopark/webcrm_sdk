module Crm; module Core
  # +SearchConfigurator+ provides methods to incrementally configure a search request
  # using chainable methods and to {#perform_search perform} this search.
  # @example
  #   search_config = Crm::Contact.
  #     where('last_name', 'equals', 'Johnson').
  #     and('locality', 'equals', 'New York').
  #     and_not('language', 'equals', 'en').
  #     sort_by('first_name').
  #     sort_order('desc').
  #     offset(1).
  #     limit(3)
  #   # => Crm::Core::SearchConfigurator
  #
  #   results = search_config.perform_search
  #   # => Crm::Core::ItemEnumerator
  #
  #   results.length # => 3
  #   results.total # => 17
  #   results.map(&:first_name) # => ['Tim', 'Joe', 'Ann']
  #
  # @example Unlimited search results
  #   search_config = Crm::Contact.
  #     where('last_name', 'equals', 'Johnson')
  #   # => Crm::Core::SearchConfigurator
  #
  #   results = search_config.perform_search
  #   # => Crm::Core::ItemEnumerator
  #
  #   results.length # => 85
  #   results.total # => 85
  #   results.map(&:first_name) # => an array of 85 first names
  # @api public
  class SearchConfigurator
    include Enumerable

    def initialize(settings = {})
      @settings = {
        filters: [],
      }.merge(settings)
    end

    # Executes the search request based on this configuration.
    # @return [ItemEnumerator] the search result.
    # @api public
    def perform_search
      @perform_search ||= Crm.search(
        filters: @settings[:filters],
        query: @settings[:query],
        limit: @settings[:limit],
        offset: @settings[:offset],
        sort_by: @settings[:sort_by],
        sort_order: @settings[:sort_order],
      )
    end

    # @!group Chainable methods

    # Returns a new {SearchConfigurator} constructed by combining
    # this configuration and the new filter.
    #
    # Supported conditions:
    # * +contains_word_prefixes+ - +field+ contains words starting with +value+.
    # * +contains_words+ - +field+ contains the words given by +value+.
    # * +equals+ - +field+ exactly corresponds to +value+ (case insensitive).
    # * +is_blank+ - +field+ is blank (omit +value+).
    # * +is_earlier_than+ - date time +field+ is earlier than +value+.
    # * +is_later_than+ - date time +field+ is later than +value+.
    # * +is_true+ - +field+ is true (omit +value+).
    # @param field [Symbol, String] the attribute name.
    # @param condition [Symbol, String] the condition, e.g. +:equals+.
    # @param value [Symbol, String, Array<Symbol, String>, nil] the value.
    # @return [SearchConfigurator]
    # @api public
    def add_filter(field, condition, value = nil)
      new_filter = Array(@settings[:filters]) + [{field: field, condition: condition, value: value}]
      SearchConfigurator.new(@settings.merge(filters: new_filter))
    end
    alias and add_filter

    # Returns a new {SearchConfigurator} constructed by combining
    # this configuration and the new negated filter.
    #
    # All filters (and their conditions) passed to {#add_filter} can be negated.
    # @param field [Symbol, String] the attribute name.
    # @param condition [Symbol, String] the condition, e.g. +:equals+.
    # @param value [Symbol, String, Array<Symbol, String>, nil] the value.
    # @return [SearchConfigurator]
    # @api public
    def add_negated_filter(field, condition, value = nil)
      negated_condition = "not_#{condition}"
      add_filter(field, negated_condition, value)
    end
    alias and_not add_negated_filter

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the given query.
    # @param new_query [String] the new query.
    # @return [SearchConfigurator]
    # @api public
    def query(new_query)
      SearchConfigurator.new(@settings.merge(query: new_query))
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the given limit.
    # @param new_limit [Fixnum] the new limit.
    # @return [SearchConfigurator]
    # @api public
    def limit(new_limit)
      SearchConfigurator.new(@settings.merge(limit: new_limit))
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # without limiting the number of search results.
    # @return [SearchConfigurator]
    # @api public
    def unlimited
      limit(:none)
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the given offset.
    # @param new_offset [Fixnum] the new offset.
    # @return [SearchConfigurator]
    # @api public
    def offset(new_offset)
      SearchConfigurator.new(@settings.merge(offset: new_offset))
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the given sort criterion.
    # @param new_sort_by [String]
    #   See {Crm.search} for the list of supported +sort_by+ values.
    # @return [SearchConfigurator]
    # @api public
    def sort_by(new_sort_by)
      SearchConfigurator.new(@settings.merge(sort_by: new_sort_by))
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the given sort order.
    # @param new_sort_order [String]
    #   See {Crm.search} for the list of supported +sort_order+ values.
    # @return [SearchConfigurator]
    # @api public
    def sort_order(new_sort_order)
      SearchConfigurator.new(@settings.merge(sort_order: new_sort_order))
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the ascending sort order.
    # @return [SearchConfigurator]
    # @api public
    def asc
      sort_order('asc')
    end

    # Returns a new {SearchConfigurator} constructed by combining this configuration
    # with the descending sort order.
    # @return [SearchConfigurator]
    # @api public
    def desc
      sort_order('desc')
    end

    # @!endgroup

    # Iterates over the search results.
    # Implicitly triggers {#perform_search} and caches its result.
    # See {ItemEnumerator#each} for details.
    # @api public
    def each(&block)
      return enum_for(:each) unless block_given?

      perform_search.each(&block)
    end

    def take(n)
      limit(n).perform_search.to_a
    end

    def first(n = :undefined)
      return take(n) unless n == :undefined
      limit(1).perform_search.first
    end

    # Returns the total number of items that match this search configuration.
    # It can be greater than +limit+.
    # Implicitly triggers {#perform_search} and caches its result.
    # @return [Fixnum] the total.
    # @api public
    def total
      perform_search.total
    end
  end
end; end
