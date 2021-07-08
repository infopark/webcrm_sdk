module Crm
  # A JustRelate WebCRM contact represents contact information about a person.
  # It can be associated with an {Account account}.
  # @api public
  class Contact < Core::BasicResource
    include Core::Mixins::Findable
    include Core::Mixins::Modifiable
    include Core::Mixins::ChangeLoggable
    include Core::Mixins::MergeAndDeletable
    include Core::Mixins::Searchable
    include Core::Mixins::Inspectable
    inspectable :id, :last_name, :first_name, :email

    # @!parse extend Core::Mixins::Findable::ClassMethods
    # @!parse extend Core::Mixins::Modifiable::ClassMethods
    # @!parse extend Core::Mixins::Searchable::ClassMethods

    # @!group Authentication and password management

    # Authenticates a contact using their +login+ and +password+.
    # @example
    #   contact = Crm::Contact.authenticate!('jane@example.org', 'correct')
    #   # => Crm::Contact
    #
    #   contact.login
    #   # => 'jane@example.org'
    #
    #   Crm::Contact.authenticate!('jane@example.org', 'wrong')
    #   # => raises AuthenticationFailed
    # @param login [String] the login of the contact.
    # @param password [String] the password of the contact.
    # @return [Contact] the authenticated contact.
    # @raise [Errors::AuthenticationFailed] if the +login+/+password+ combination is wrong.
    # @api public
    def self.authenticate!(login, password)
      new(Core::RestApi.instance.put("#{path}/authenticate",
          {'login' => login, 'password' => password}))
    end

    # Authenticates a contact using their +login+ and +password+.
    # @example
    #   contact = Crm::Contact.authenticate('jane@example.org', 'correct')
    #   # => Crm::Contact
    #
    #   contact.login
    #   # => 'jane@example.org'
    #
    #   Crm::Contact.authenticate('jane@example.org', 'wrong')
    #   # => nil
    # @param login [String] the login of the contact.
    # @param password [String] the password of the contact.
    # @return [Contact, nil] the authenticated contact. +nil+ if authentication failed.
    # @api public
    def self.authenticate(login, password)
      authenticate!(login, password)
    rescue Errors::AuthenticationFailed
      nil
    end

    # Sets the new password.
    # @param new_password [String] the new password.
    # @return [self] the updated contact.
    # @api public
    def set_password(new_password)
      load_attributes(Core::RestApi.instance.put("#{path}/set_password",
          {'password' => new_password}))
    end

    # Generates a password token.
    #
    # Use case: A project sends an email to the contact. The email contains a link to
    # the project web app. The link contains the param +?token=...+.
    # The web app retrieves and parses the token
    # and passes it to {Contact.set_password_by_token}.
    # @return [String] the generated token.
    # @api public
    def generate_password_token
      Core::RestApi.instance.post("#{path}/generate_password_token", {})['token']
    end

    # Sets a contact's new password by means of the token. Generate a token by calling
    # {#send_password_token_email} or {#generate_password_token}.
    #
    # Use case: A contact clicks a link (that includes a token) in an email
    # to get to a password change page.
    # @param new_password [String] the new password.
    # @param token [String] the given token.
    # @return [Contact] the updated contact.
    # @raise [Errors::ResourceNotFound] if +token+ is invalid.
    # @api public
    def self.set_password_by_token(new_password, token)
      new(Core::RestApi.instance.put("#{path}/set_password_by_token", {
        'password' => new_password,
        'token' => token,
      }))
    end

    # Clears the contact's password.
    # @return [self] the updated contact.
    # @api public
    def clear_password
      load_attributes(Core::RestApi.instance.put("#{path}/clear_password", {}))
    end

    # Sends a password token by email to this contact.
    #
    # Put a link to the project web app into the +password_request_email_body+ template.
    # The link should contain the +?token=...+ parameter, e.g.:
    #
    # <tt>https://example.com/user/set_password?token={{password_request_token}}</tt>
    #
    # The web app can then pass the token to {Contact.set_password_by_token}.
    # @return [void]
    # @api public
    def send_password_token_email
      Core::RestApi.instance.post("#{path}/send_password_token_email", {})
    end

    # @!endgroup
  end
end
