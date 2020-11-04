# Infopark WebCRM SDK

[![Gem Version](https://badge.fury.io/rb/infopark_webcrm_sdk.svg)](http://badge.fury.io/rb/infopark_webcrm_sdk)
[![Build Status](https://travis-ci.org/infopark/webcrm_sdk.svg?branch=master)](https://travis-ci.org/infopark/webcrm_sdk)

[Infopark WebCRM](https://infopark.com/) is a cloud-based CRM.
The Infopark WebCRM SDK makes CRM content available to your Ruby application.
It is a client of the Infopark WebCRM REST API v2.

This SDK lets you access and manipulate accounts and contacts, for example, perform searches, etc.

## Installation

Add `infopark_webcrm_sdk` to your `Gemfile`:

    gem 'infopark_webcrm_sdk'

Install the gem with [Bundler](http://bundler.io/):

    bundle install

## Configuration

```ruby
require 'infopark_webcrm_sdk'

Crm.configure do |config|
  config.tenant  = 'my_tenant'
  config.login   = 'my_login'
  config.api_key = 'my_api_key'
end
```

## Documentation

The documentation is available at [RubyDoc.info](http://www.rubydoc.info/gems/infopark_webcrm_sdk).

## Example Usage

The Infopark WebCRM SDK provides the following Infopark WebCRM resources to your Ruby application:

* {Crm::Account}
* {Crm::Activity}
* {Crm::Collection}
* {Crm::Contact}
* {Crm::EventContact}
* {Crm::Event}
* {Crm::Mailing}
* {Crm::TemplateSet}
* {Crm::Type}

Most of these classes have methods such as {Crm::Core::Mixins::Findable::ClassMethods#find find}, {Crm::Core::Mixins::Modifiable::ClassMethods#create create}, {Crm::Core::Mixins::Modifiable#update update}, {Crm::Core::Mixins::Searchable::ClassMethods#query query}, and {Crm::Core::Mixins::Searchable::ClassMethods#where where}.

### Creating a Contact

```ruby
contact = Crm::Contact.create({
  first_name: 'John',
  last_name: 'Smith',
  language: 'en',
  locality: 'New York',
})
# => Crm::Contact

contact.first_name
# => 'John'

contact.id
# => 'e70a7123f499c5e0e9972ab4dbfb8fe3'
```

### Fetching and Updating a Contact

```ruby
# Retrieve the contact by ID
contact = Crm::Contact.find('e70a7123f499c5e0e9972ab4dbfb8fe3')
# => Crm::Contact

contact.last_name
# => 'Smith'

contact.locality
# => 'New York'

# Change this contact's locality
contact.update({locality: 'Boston'})
# => Crm::Contact

contact.last_name
# => 'Smith'

contact.locality
# => 'Boston'
```

### Searching for Contacts

```ruby
Crm::Contact.where(:login, :equals, 'root').first
# => Crm::Contact

Crm::Contact.where(:locality, :equals, 'Boston').
  and(:last_name, :contains_word_prefixes, 'S').
  sort_by(:last_name).
  sort_order(:desc).
  limit(2).
  map(&:last_name)
# => ['Smith', 'Simpson']
```

## License

Copyright (c) 2015 - 2020 [Infopark AG](https://infopark.com).

This software can be used and modified in accordance with the GNU Lesser General Public License
(LGPL-3.0). Please refer to LICENSE for details.
