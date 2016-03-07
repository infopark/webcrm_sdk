module Crm
  # +TemplateSet+ represents the Infopark WebCRM template set singleton.
  # The templates of the {.singleton template set singleton} can be used to render customized text,
  # e.g. a mailing greeting or a password request email body (+password_request_email_body+).
  #
  # Infopark WebCRM uses the {http://liquidmarkup.org/ Liquid template engine} for evaluating
  # the templates.
  # @api public
  class TemplateSet < Core::BasicResource
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::Inspectable

    def self.path
      resource_name
    end

    # Returns the template set singleton.
    # @return [TemplateSet]
    # @api public
    def self.singleton
      new({}).reload
    end

    # Updates the attributes of this template set.
    # See {Core::Mixins::Modifiable#update Modifiable#update} for details.
    # @return [self] the updated template set singleton.
    # @api public
    def update(attributes)
      load_attributes(
          Core::RestApi.instance.put(path, attributes, if_match_header))
    end

    # Renders a preview of the template set using the specified context items.
    # This is for testing your (future) templates.
    #
    # * All templates contained in the set are rendered.
    # * You may temporally add any number of +templates+ to the set
    #   (just for the purpose of rendering).
    # * Pass as +context+ items all the instances (e.g. contact, acticity)
    #   for which the templates should be rendered.
    #
    # Templates have access to the context items.
    # You can use the following keys to represent context items:
    # * +account+
    # * +contact+
    # * +activity+
    # * +mailing+
    # * +event+
    # The keys expect an ID as input. For example, <tt>{"account" => "23"}</tt> allows
    # the template to access +account.name+ of the account with the ID +23+.
    #
    # @example
    #   contact.first_name
    #   # => 'Michael'
    #
    #   template_set.templates['digest_email_subject']
    #   # => 'Summary for {{contact.first_name}}'
    #
    #   template_set.render_preview(
    #     templates: { greeting: 'Dear {{contact.first_name}}, {{foo}}' },
    #     context: {contact: contact.id, foo: 'welcome!'}
    #   )
    #   # => {
    #   #  ...
    #   #  'digest_email_subject' => 'Summary for Michael',
    #   #  'greeting' => 'Dear Michael, welcome!',
    #   #  ...
    #   # }
    # @param templates [Hash{String => String}]
    #   the set of additional or temporary replacement templates to render.
    # @param context [Hash{String => String}] the context items of the preview.
    # @return [Hash{String => String}] the processed templates.
    # @api public
    def render_preview(templates: {}, context: {})
      Core::RestApi.instance.post("#{path}/render_preview", {
        'templates' => templates,
        'context' => context,
      })
    end
  end
end
