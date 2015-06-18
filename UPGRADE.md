# Upgrade Guide

This guide assists you in upgrading from the **Infopark WebCRM Connector** (which uses API 1) to **Infopark WebCRM SDK** (which uses API 2).

You can upgrade incrementally to the Infopark WebCRM SDK.
This means that you don't need to upgrade your whole project at once.
Instead, include both the Infopark WebCRM Connector and the Infopark WebCRM SDK in your project and replace the code use case by use case.
Finally, remove the Infopark WebCRM Connector from the project.

To begin with, put both gems into the `Gemfile` of your project:

```ruby
gem "infopark_crm_connector"
gem "infopark_webcrm_sdk"
```

## Configuring the Infopark WebCRM SDK

Then, configure the Infopark WebCRM SDK to use your personal credentials when connecting to the Infopark WebCRM REST API.
You probably have a `webcrm.rb` or `crm_connector.rb` initializer file in your project which already contains the Infopark WebCRM Connector configuration.
Add the following lines to this file.

```ruby
require 'infopark_webcrm_sdk'

Crm.configure do |config|
  config.tenant  = ENV["CRM_TENANT"]
  config.login   = ENV["CRM_LOGIN"]
  config.api_key = ENV["CRM_API_KEY"]
end
```

Instead of reading the configuration values from the `ENV` you may also want to read them from a configuration file.

## General remarks

### The Crm namespace

All Infopark WebCRM SDK classes live under the `Crm` namespace whereas Infopark WebCRM Connector classes live under the `Infopark::Crm` namespace.

```ruby
# old:
Infopark::Crm::Contact.find(contact_id)
# new:
Crm::Contact.find(contact_id)
```

In case the resource could not be found, a `Crm::Errors::ResourceNotFound` error is raised.
Infopark WebCRM SDK will never raise an `ActiveResource::ResourceNotFound` error.
More on errors in the next section.

### Errors tell exactly what went wrong

For example, when trying to fetch a resource that could not be found, the `Crm::Errors::ResourceNotFound` error has a `missing_ids` property telling you the list of IDs that could not be found.

```ruby
begin
  Crm::Contact.find("foo")
rescue Crm::Errors::ResourceNotFound => e
  e.message # => "Items could not be found. Missing IDs: foo"
  e.missing_ids # => ["foo"]
end
```

Or, when the Infopark WebCRM backend refuses to save a resource due to unsatisfied validation rules, the error contains the details.

```ruby
begin
  Crm::Contact.create({
    first_name: "John",
    gender: "i don't know",
  })
rescue Crm::Errors::InvalidValues => e
  e.message # => "Validate the parameters and try again. gender is not included in the list: N, M, F, language is not included in the list, and last_name can't be blank."
  e.validation_errors
  # => [
  #   {
  #     "attribute" => "gender",
  #     "code" => "inclusion",
  #     "message" => "gender is not included in the list: N, M, F"
  #   },
  #   {
  #     "attribute" => "language",
  #     "code" => "inclusion",
  #     "message" => "language is not included in the list"
  #   },
  #   {
  #     "attribute" => "last_name",
  #     "code" => "blank",
  #     "message" => "last_name can't be blank"
  #   }
  # ]
end
```

Validation errors contain the names of the attributes whose values are invalid, symbolic codes that you can use to look up custom translations of the error messages and English messages for convenience.
The symbolic codes are the Rails validation error codes where possible, e.g. `blank` and `inclusion`.
Infopark WebCRM adds its own codes such as `invalid_comment_contact_id` and `liquid_syntax_error`.

Furthermore, when updating a resource, Infopark WebCRM complains about attributes not defined in the resource type.

```ruby
begin
  Crm::Contact.create({
    foo: "bar",
  })
rescue Crm::Errors::InvalidKeys => e
  e.message # => "Unknown keys specified. foo is unknown."
  e.validation_errors
  # => [
  #   {
  #     "attribute" => "foo",
  #     "code" => "unknown",
  #     "message" => "foo is unknown"
  #   }
  # ]
end
```

However, trying to set an internal read-only attribute such as `created_at` is ignored.

A list of errors and their properties can be found in the Infopark WebCRM SDK YARD docs.

### Write form models including their custom logic for every use case

One big change in the Infopark WebCRM SDK is that model classes are no longer based on `ActiveResource`.
They are much simpler now, and they don't behave like `ActiveModel` objects any more.
Instead of modifying a resource locally and then asking it to `save` itself,  the Infopark WebCRM SDK requires the resource to be changed by passing the new attribute values to the `update` method.
Analogously, for creating a new resource, pass all of its attributes to `create`.

```ruby
contact = Crm::Contact.create({
  first_name: "John",
  last_name: "Smith",
  language: "en",
  locality: "New York",
  gender: "M",
})
contact.locality # => "New York"

contact.update({
  locality: "Hamburg",
  language: "de",
})
contact.locality # => "Hamburg"
```

This means that you can no longer use them as form objects in your controllers and views.
You'd rather write a plain Ruby class for every use case, implement the `ActiveModel` interface and your custom logic in this class, and delegate to Infopark WebCRM SDK models for communicating with the Infopark WebCRM REST API.
For further details, see the API docs.

We recommend using the `active_attr` gem to simplify implementing the `ActiveModel` interface.

### Accessing attributes

You can access the attributes of an Infopark WebCRM SDK resource by means of method calls or the `[]` operator.

```ruby
contact = Crm::Contact.find(contact_id)
contact.last_name # => "Smith"
contact[:last_name] # => "Smith"
contact["last_name"] # => "Smith"
```

### Every attribute has a sane value

Attributes not set have a default value according to their attribute type.
Assuming that an Infopark WebCRM contact has no value for the `first_name` string attribute, reading it results in `""`, the empty string, not `nil`.
The same rule applies to numbers, boolean, arrays and hashes.

The only exception to this rule are date attributes whose values are in fact `nil` if they are not set.
If a date attribute has a value, it is automatically parsed and returned as a `Time` instance in the local timezone.

The consequence of this is that you don't need to write a lot of `nil` checks and no longer need to parse dates yourself.

### Renamed attributes

A couple of attributes were renamed in API 2.
You can access attributes using the Infopark WebCRM Connector and the old attribute name or the Infopark WebCRM SDK and the new attribute name.

The following attributes were renamed for all resources.

* `kind` => `type_id` (e.g. `"contact-form"`)
* `type` => `base_type` (e.g. `"Activity"`)

Further attribute name changes are documented below.

### Authentication

Infopark WebCRM SDK offers two methods for authenticating a contact.

1. `Crm::Contact.authenticate` returns the authenticated contact or `nil`.
2. `Crm::Contact.authenticate!` returns the authenticated contact or raises a `Crm::Errors::AuthenticationFailed` error.

### All resources have a changelog

The changes history known from the WebCRM GUI is now also available in the new API.
You can retrieve up to 100 changelog entries of any resource.
They are sorted in reverse chronological order.

```ruby
contact = Crm::Contact.find(contact_id)
contact.changes.each do |change|
  change.changed_at # => 2014-11-26 15:37:27 +0100
  change.changed_by # => "root"
  change.details(limit: 1).each do |attr_name, detail|
    attr_name # => "email"
    detail.before # => "john.smith@example.org"
    detail.after # => "johann.schmidt@example.org"
  end
end
```

### All resources can be undeleted

Previously, there was no way to undelete a deleted resource by means of the API.
With the API 2, all resources have an `undelete` method.

```ruby
contact = Crm::Contact.find(contact_id)
contact.deleted? # => true
contact.undelete
contact.deleted? # => false
```

## The individual resources: changes & features

### Search

Infopark WebCRM comes with a global search.
All resource types are searched simultaneously.
The following example finds both accounts and contacts located in Rome.
Both accounts and contacts have a locality attribute.

```ruby
Crm.search(
  filters: [
    {field: 'locality', condition: 'equals', value: 'Rome'},
  ],
  sort_by: 'updated_at'
)
```

In order to limit the search hits to contacts, add another filter.

```ruby
Crm.search(
  filters: [
    {field: 'locality', condition: 'equals', value: 'Rome'},
    {field: 'base_type', condition: 'equals', value: 'Contact'},
  ],
  sort_by: 'updated_at'
)
```

The power of the new search API comes into play when building more complex queries.
Based on this low-level `search` method, the SDK lets you compose search queries by means of method chaining.
Start with the `where` method, then append methods such as `and`, `limit`, and `sort_by` to further refine the search.
Finally, run the search by iterating over the results:

```ruby
Crm::Activity.
    where("type_id", :equals, "support-case").
    and("contact_id", :equals, contact_id).
    and_not("state", :equals, "closed").
    query("I have got a problem").
    limit(10).
    sort_by("updated_at").desc.
    each do |activity|
      puts activity.title
    end
```

Further examples to illustrate the new search features:

```ruby
# old:
Infopark::Crm::Contact.search(params: {q: "something"}).take(10)
Infopark::Crm::Contact.search(params: {login: login}).first
# new:
Crm::Contact.query("something").limit(10).to_a
Crm::Contact.where(:login, :equals, login).limit(1).first
```

### Accounts

The `merge_and_delete` method merges two accounts and deletes the one for which the method was called.
This feature is already known from the WebCRM GUI.
All items associated with the account to be deleted, e.g. activities, are transfered to the target account.

```ruby
account_to_delete = Crm::Account.find(account_id)
account_to_delete.merge_and_delete(target_account_id)
account_to_delete.deleted? # => true
```

### Activities

When associating an attachment with an activity comment, you can pass an open file instead of an attachment ID.
In this case, the Infopark WebCRM SDK automatically uploads the file content using the attachments API.
It then references this attachment ID in the `comment_attachments` field.

```ruby
activity = Crm::Activity.create({
  type_id: 'support-case',
  state: 'created',
  title: 'I have a question',
  comment_notes: 'Please see the attached screenshot.',
  comment_attachments: [File.new('screenshot.jpg')],
})
activity.comments.last.attachments.first.download_url
# => "https://.../screenshot.jpg"
```

The following activity attributes were renamed in API 2:

* `appointment_dtend_at` => `dtend_at`
* `appointment_dtstart_at` => `dtstart_at`
* `appointment_location` => `location`
* `contact_id` => `contact_ids`

### AttachmentStore

Actions related to attachments were streamlined.
The Ruby class responsible for attachments is now `AttachmentStore`.
The main class methods of the attachment store are `generate_upload_permission` and `generate_download_url`.

When uploading attachments using Ruby, we recommend utilizing the implicit uploading facility of activity comments as a shortcut.

### Collections

The `Collection` API is new.
An Infopark WebCRM collection is a saved search.
The search filters as well as the search results are part of the collection.

```ruby
collection = Crm::Collection.create({
  title: 'My Collection',
  collection_type: 'contact',
  filters: [
    [
      {field: 'contact.last_name', condition: 'equals', value: 'Smith'}
    ]
  ]
})
```

To execute such a saved search, call `compute`.

```ruby
collection.compute
```

The results are persisted and can be accessed via `output_items`.

```ruby
collection.output_items.each do |contact|
  contact.last_name # => "Smith"
end
```

For details, see the Infopark WebCRM SDK docs.

### Contacts

`Contact#merge_and_delete` works analogously to `Account#merge_and_delete`.
Refer to the "Accounts" section for details.

The following contact attributes were renamed in API 2:

* `password_request_at` => `password_requested_at`

### EventContacts

With the exception of the renamed common attributes (see above), nothing has changed.

### Events

The following event attributes were renamed in API 2:

* `custom_attributes` (array) => `attribute_definitions` (hash) + `attribute_order` (array)

### Mailings

You can render the plain-text and HTML templates of a mailing as they would look for a given contact ID by means of `Mailing#render_preview`.

```ruby
mailing = Crm::Mailing.create({
  email_from: "Marketing <marketing@example.com>",
  email_reply_to: "marketing-replyto@example.com",
  email_subject: "Invitation to our exhibition",
  html_body: '<h1>Welcome {{contact.first_name}} {{contact.last_name}}</h1>',
  text_body: 'Welcome {{contact.first_name}} {{contact.last_name}}',
  title: 'Our Annual Exhibition',
  type_id: 'newsletter',
})
mailing.render_preview(contact_id)
# => {
#   "email_from" => "Marketing <marketing@example.com>",
#   "email_reply_to" => "marketing-replyto@example.com",
#   "email_subject" => "Invitation to our exhibition",
#   "email_to" => "john.smith@example.org",
#   "html_body" => "<h1>Welcome John Smith</h1>",
#   "text_body" => "Welcome John Smith",
# }
```

`Mailing#send_single_email` sends an e-mail to an individual contact after the mailing has already been released.

`Mailing#send_me_a_proof_email` sends an e-mail to the authenticated API user, i.e. to the user you configured in the `Crm.configure` block.

`Mailing#release` releases a mailing and sends e-mails to all recipients.

```ruby
recipients = Crm::Collection.create({
  title: 'Newsletter Recipients',
  collection_type: 'contact',
  filters: [
    [
      {field: 'contact.locality', condition: 'equals', value: "Berlin"},
    ]
  ]
})
recipients.compute

newsletter_mailing = Crm::Mailing.create({
  title: 'Newsletter',
  type_id: 'newsletter',
  collection_id: recipients.id,
  email_from: "Marketing <marketing@example.com>",
})
newsletter_mailing.release
```

The following mailing attributes were renamed in API 2:

* `contact_collection_id` => `collection_id`
* `dtstart_at` => `planned_release_at`
* `body` => `text_body`


### TemplateSet

Templates can no longer be accessed using the `Infopark::Crm::System.templates` hash.
Instead, they are now a normal attribute, `templates`, of the `Crm::TemplateSet.singleton` resource.

```ruby
ts = Crm::TemplateSet.singleton
ts.templates['password_request_email_from'] # => "bounces@example.com"
ts.updated_at # => 2015-02-16 11:19:28 +0100
ts.updated_by # => "root"
```

Compared to the Infopark WebCRM Connector, setting a subset of templates is sufficient.
Templates that are not specified are no longer deleted.
Set templates explicitly to `nil` to remove them from the template set.

```ruby
ts = Crm::TemplateSet.singleton
ts.update(templates: {
  'password_request_email_from' => nil,
  'foo' => 'bar',
})
ts.templates['password_request_email_from'] # => nil
ts.templates['foo'] # => "bar"
```

### Types

Types were formerly known as custom types.

`Crm::Type.all` retrieves a list of all types, i.e. custom types and built-in types.

Every type has an `id`, e.g. `contact` or `support-case`, which is referenced as `type_id` by instances of these classes.

`Crm::Type.find` loads the type by its ID.

```ruby
contact = Crm::Contact.find(contact_id)
contact.type_id # => "contact"

contact_type = Crm::Type.find("contact")
contact_type.base_type # => "Type"
contact_type.id # => "contact"
contact_type.item_base_type # => "Contact"
contact_type.attribute_definitions
# => {
#   "custom_my_foo" => {
#     "title" => "my foo attribute",
#     "mandatory" => false,
#     "max_length" => 80,
#     "attribute_type" => "string",
#     "create" => true,
#     "update" => true,
#     "read" => true,
#   }
# }

support_case = Crm::Activity.find(support_case_id)
support_case.type_id # => "support-case"

support_case_type = Crm::Type.find('support-case')
support_case_type.base_type # => "Type"
support_case_type.id # => "support-case"
support_case_type.item_base_type # => "Activity"
support_case_type.attribute_definitions # => {}
```
