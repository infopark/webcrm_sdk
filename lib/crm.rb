require 'active_support/all'
require 'net/http/post/multipart'
require 'crm/errors'

# @api public
module Crm
  # Configures the Infopark WebCRM SDK.
  # The config keys +tenant+, +login+ and +api_key+ must be provided.
  # @example
  #   Crm.configure do |config|
  #     config.tenant  = 'my_tenant'
  #     config.login   = 'my_login'
  #     config.api_key = 'my_api_key'
  #   end
  # @yieldparam config [Crm::Core::Configuration]
  # @return [void]
  # @api public
  def self.configure
    config = ::Crm::Core::Configuration.new
    yield config
    config.validate!
    Core::RestApi.instance = Core::RestApi.new(config.endpoint_uri, config.login, config.api_key)
  end

  def self.autoload_module(mod, mod_source)
    mod_dir = mod_source.gsub(/\.rb$/, '')
    Dir.glob("#{mod_dir}/*.rb").each do |file|
      name = File.basename(file, ".rb")
      mod.autoload name.camelcase, file
    end
  end

  # Fetches multiple items by +ids+.
  # The base type of the items can be mixed (e.g. a {Crm::Contact} or {Crm::Account}).
  # @example
  #   Crm.find('e70a7123f499c5e0e9972ab4dbfb8fe3')
  #   # => Crm::Contact
  #
  #   Crm.find('e70a7123f499c5e0e9972ab4dbfb8fe3', '2185dd25c2f4fa41fbef422c1b9cfc38')
  #   # => Crm::Core::ItemEnumerator
  #
  #   Crm.find(['e70a7123f499c5e0e9972ab4dbfb8fe3', '2185dd25c2f4fa41fbef422c1b9cfc38'])
  #   # => Crm::Core::ItemEnumerator
  # @param ids [String, Array<String>] A single ID or a list of IDs.
  # @return [Crm::Core::BasicResource]
  #   A {Crm::Core::BasicResource single item} if the method was called with a single ID.
  # @return [Crm::Core::ItemEnumerator]
  #   An {Crm::Core::ItemEnumerator enumerator} if the method was called with multiple IDs.
  # @raise [Errors::ResourceNotFound] if at least one of the IDs could not be found.
  # @api public
  def self.find(*ids)
    flattened_ids = ids.flatten
    if flattened_ids.compact.blank?
      raise Crm::Errors::ResourceNotFound.new(
          "Items could not be found.", flattened_ids)
    end
    enumerator = Core::ItemEnumerator.new(flattened_ids)

    if ids.size == 1 && !ids.first.kind_of?(Array)
      enumerator.first
    else
      enumerator
    end
  end

  # Performs a search.
  # Retrieves only IDs and passes them to an {Core::ItemEnumerator ItemEnumerator}.
  # The {Core::ItemEnumerator ItemEnumerator} then fetches the items on demand.
  #
  # The search considers the following base types:
  # * {Crm::Account Account}
  # * {Crm::Activity Activity}
  # * {Crm::Collection Collection}
  # * {Crm::Contact Contact}
  # * {Crm::Event Event}
  # * {Crm::EventContact EventContact}
  # * {Crm::Mailing Mailing}
  # @example
  #   Crm.search([{field: 'last_name', condition: 'equals', value: 'Johnson'}])
  #   # => Crm::Core::ItemEnumerator with all contacts with last name Johnson.
  #
  #   Crm.search(
  #     [
  #       {field: 'last_name', condition: 'equals', value: 'Johnson'},
  #       {field: 'locality', condition: 'equals', value: 'Boston'}
  #     ],
  #     limit: 20,
  #     offset: 10,
  #     sort_by: 'created_at',
  #     sort_order: 'desc'
  #   )
  #   # => Crm::Core::ItemEnumerator with max 20 contacts with last name Johnson from Boston.
  # @param filters [Array<Hash{String => String}>]
  #   Array of filters, each filter is a hash with three properties:
  #   +field+, +condition+, +value+. Filters are AND expressions.
  # @param query [String]
  #   The search term of a full-text search for words starting with the term
  #   (case-insensitive prefix search). Affects score.
  # @param limit [Fixnum] The number of results to return at most. Minimum: +0+.
  #    Use +:none+ to specify no limit. Default: +:none+.
  # @param offset [Fixnum] The number of results to skip. Minimum: +0+. Default: +0+.
  # @param sort_by [String] The name of the attribute by which the result is to be sorted:
  #   * +base_type+
  #   * +created_at+ (server default)
  #   * +dtstart_at+
  #   * +first_name+
  #   * +last_name+
  #   * +score+
  #   * +title+
  #   * +updated_at+
  # @param sort_order [String] One of +asc+ (ascending) or +desc+ (descending).
  #   For +sort_by+ +score+, the only valid sort order is +desc+ (can be omitted).
  # @return [Crm::Core::ItemEnumerator]
  #   An {Crm::Core::ItemEnumerator enumerator} to iterate over the found items.
  # @api public
  def self.search(filters: nil, query: nil, limit: :none, offset: 0, sort_by: nil, sort_order: nil)
    server_limit = 100
    limit = Float::INFINITY if limit.nil? || limit == :none
    offset ||= 0

    ids = []
    total = nil
    initial_offset = offset

    loop do
      params = {
        'filters' => filters,
        'query' => query,
        'limit' => [limit, server_limit].min,
        'offset' => offset,
        'sort_by' => sort_by,
        'sort_order' => sort_order,
      }.reject { |k, v| v.nil? }
      search_results = Core::RestApi.instance.post('search', params)
      ids.concat(search_results['results'].map { |r| r['id'] })
      total = search_results['total']
      break if ids.size >= [limit, (total - initial_offset)].min
      limit -= server_limit
      offset += server_limit
    end

    Core::ItemEnumerator.new(ids, total: total)
  end

  autoload_module(self, File.expand_path(__FILE__))
end

Crm::Core::LogSubscriber.attach_to :crm
