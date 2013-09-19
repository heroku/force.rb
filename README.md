# Force

[![travis-ci](https://travis-ci.org/ejholmes/force.png?branch=master)](https://travis-ci.org/ejholmes/force) [![Code Climate](https://codeclimate.com/github/ejholmes/force.png)](https://codeclimate.com/github/ejholmes/force) [![Dependency Status](https://gemnasium.com/ejholmes/force.png)](https://gemnasium.com/ejholmes/force)

Force is a ruby gem for the [Salesforce REST api](http://www.salesforce.com/us/developer/docs/api_rest/index.htm).
It's meant to be a lighter weight alternative to the [databasedotcom gem](https://github.com/heroku/databasedotcom) that offers
greater flexibility and more advanced functionality.

Features include:

* A clean and modular architecture using [Faraday middleware](https://github.com/technoweenie/faraday) and [Hashie::Mash](https://github.com/intridea/hashie/tree/v1.2.0)'d responses.
* Support for interacting with multiple users from different orgs.
* Support for parent-to-child relationships.
* Support for aggregate queries.
* Support for the [Streaming API](#streaming)
* Support for blob data types.
* Support for GZIP compression.
* Support for [custom Apex REST endpoints](#custom-apex-rest-endpoints).
* Support for dependent picklists.
* Support for decoding [Force.com Canvas](http://www.salesforce.com/us/developer/docs/platform_connectpre/canvas_framework.pdf) signed requests. (NEW!)

[Documentation](http://rubydoc.info/gems/force/frames) | [Changelog](https://github.com/ejholmes/force/tree/master/CHANGELOG.md)

## Installation

Add this line to your application's Gemfile:

    gem 'force'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install force

## Usage

Force is designed with flexibility and ease of use in mind. By default, all api calls will
return [Hashie::Mash](https://github.com/intridea/hashie/tree/v1.2.0) objects,
so you can do things like `client.query('select Id, (select Name from Children__r) from Account').Children__r.first.Name`.

### Initialization

Which authentication method you use really depends on your use case. If you're
building an application where many users from different orgs are authenticated
through oauth and you need to interact with data in their org on their behalf,
you should use the OAuth token authentication method.

If you're using the gem to interact with a single org (maybe you're building some
salesforce integration internally?) then you should use the username/password
authentication method.

#### OAuth token authentication

```ruby
client = Force.new :oauth_token => 'oauth token',
  :instance_url  => 'instance url'
```

Although the above will work, you'll probably want to take advantage of the
(re)authentication middleware by specifying a refresh token, client id and client secret:

```ruby
client = Force.new :oauth_token => 'oauth token',
  :refresh_token => 'refresh token',
  :instance_url  => 'instance url',
  :client_id     => 'client_id',
  :client_secret => 'client_secret'
```

#### Username/Password authentication

If you prefer to use a username and password to authenticate:

```ruby
client = Force.new :username => 'foo',
  :password       => 'bar',
  :security_token => 'security token',
  :client_id      => 'client_id',
  :client_secret  => 'client_secret'
```

You can also set the username, password, security token, client id and client
secret in environment variables:

```bash
export SALESFORCE_USERNAME="username"
export SALESFORCE_PASSWORD="password"
export SALESFORCE_SECURITY_TOKEN="security token"
export SALESFORCE_CLIENT_ID="client id"
export SALESFORCE_CLIENT_SECRET="client secret"
```

```ruby
client = Force.new
```
### Proxy Support

You can specify a http proxy using the :proxy_uri option, as follows:

```ruby
client = Force.new :username => 'foo',
  :password       => 'bar',
  :security_token => 'security token',
  :client_id      => 'client_id',
  :client_secret  => 'client_secret',
  :proxy_uri      => 'http://proxy.example.com:123'
```
This paramter also will accept 'http://user@password:proxy.example.com:123' or using the environemnt variable PROXY_URI.

#### Sandbox Orgs

You can connect to sandbox orgs by specifying a host. The default host is
'login.salesforce.com':

```ruby
client = Force.new :host => 'test.salesforce.com'
```
The host can also be set with the environment variable SALESFORCE_HOST.

#### Global configuration

You can set any of the options passed into Force.new globally:

```ruby
Force.configure do |config|
  config.client_id     = 'foo'
  config.client_secret = 'bar'
end
```

### Bang! methods

All the CRUD methods (create, update, upsert, destroy) have equivalent methods with
a ! at the end (create!, update!, upsert!, destroy!), which can be used if you need
to do some custom error handling. The bang methods will raise exceptions, while the
non-bang methods will return false in the event that an exception is raised. This
works similarly to ActiveRecord.

* * *

### query

```ruby
accounts = client.query("select Id, Something__c from Account where Id = 'someid'")
# => #<Force::Collection >

account = accounts.first
# => #<Force::SObject >

account.sobject_type
# => 'Account'

account.Id
# => "someid"

account.Name = 'Foobar'
account.save
# => true

account.destroy
# => true
```

### find

```ruby
client.find('Account', '001D000000INjVe')
# => #<Force::SObject Id="001D000000INjVe" Name="Test" LastModifiedBy="005G0000002f8FHIAY" ... >

client.find('Account', '1234', 'Some_External_Id_Field__c')
# => #<Force::SObject Id="001D000000INjVe" Name="Test" LastModifiedBy="005G0000002f8FHIAY" ... >
```

### search

```ruby
# Find all occurrences of 'bar'
client.search('FIND {bar}')
# => #<Force::Collection >

# Find accounts match the term 'genepoint' and return the Name field
client.search('FIND {genepoint} RETURNING Account (Name)').map(&:Name)
# => ['GenePoint']
```

### create

```ruby
# Add a new account
client.create('Account', Name: 'Foobar Inc.')
# => '0016000000MRatd'
```

### update

```ruby
# Update the Account with Id '0016000000MRatd'
client.update('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp')
# => true
```

### upsert

```ruby
# Update the record with external ID of 12
client.upsert('Account', 'External__c', External__c: 12, Name: 'Foobar')
```

### destroy

```ruby
# Delete the Account with Id '0016000000MRatd'
client.destroy('Account', '0016000000MRatd')
# => true
```

### describe

```ruby
# get the global describe for all sobjects
client.describe
# => { ... }

# get the describe for the Account object
client.describe('Account')
# => { ... }
```

### describe_layouts

```ruby
# get layouts for an sobject type
client.describe_layout('Account')
# => { ... }

# get the details for a specific layout
client.describe_layouts('Account', '012E0000000RHEp')
# => { ... }
```

### picklist\_values


```ruby
client.picklist_values('Account', 'Type')
# => [#<Force::Mash label="Prospect" value="Prospect">]

# Given a custom object named Automobile__c with picklist fields
# Model__c and Make__c, where Model__c depends on the value of
# Make__c.
client.picklist_values('Automobile__c', 'Model__c', :valid_for => 'Honda')
# => [#<Force::Mash label="Civic" value="Civic">, ... ]
```

* * *

### authenticate!

Performs an authentication and returns the response. In general, calling this
directly shouldn't be required, since the client will handle authentication for
you automatically. This should only be used if you want to force
an authentication before using the streaming api, or you want to get some
information about the user.

```ruby
response = client.authenticate!
# => #<Force::Mash access_token="..." id="https://login.salesforce.com/id/00DE0000000cOGcMAM/005E0000001eM4LIAU" instance_url="https://na9.salesforce.com" issued_at="1348465359751" scope="api refresh_token" signature="3fW0pC/TEY2cjK5FCBFOZdjRtCfAuEbK1U74H/eF+Ho=">

# Get the user information
info = client.get(response.id).body
info.user_id
# => '005E0000001eM4LIAU'
```

* * *

### File Uploads

Using the new [Blob Data](http://www.salesforce.com/us/developer/docs/api_rest/Content/dome_sobject_insert_update_blob.htm) api feature (500mb limit):

```ruby
client.create 'Document', FolderId: '00lE0000000FJ6H',
  Description: 'Document test',
  Name: 'My image',
  Body: Force::UploadIO.new(File.expand_path('image.jpg', __FILE__), 'image/jpeg'))
```

Using base64 encoded data (37.5mb limit):

```ruby
client.create 'Document', FolderId: '00lE0000000FJ6H',
  Description: 'Document test',
  Name: 'My image',
  Body: Base64::encode64(File.read('image.jpg'))
```

_See also: http://www.salesforce.com/us/developer/docs/api_rest/Content/dome_sobject_insert_update_blob.htm_

* * *

### Downloading Attachments

Force also makes it incredibly easy to download Attachments:

```ruby
attachment = client.query('select Id, Name, Body from Attachment').first
File.open(attachment.Name, 'wb') { |f| f.write(attachment.Body) }
```

* * *

### Custom Apex REST endpoints

You can use Force to interact with your custom REST endpoints, by using
`.get`, `.put`, `.patch`, `.post`, and `.delete`.

For example, if you had the following Apex REST endpoint on Salesforce:

```apex
@RestResource(urlMapping='/FieldCase/*')
global class RESTCaseController {
  @HttpGet
  global static List<Case> getOpenCases() {
    String companyName = RestContext.request.params.get('company');
    Account company = [ Select ID, Name, Email__c, BillingState from Account where Name = :companyName];

    List<Case> cases = [SELECT Id, Subject, Status, OwnerId, Owner.Name from Case WHERE AccountId = :company.Id];
    return cases;
  }
}
```

Then you could query the cases using Force:

```ruby
client.get '/services/apexrest/FieldCase', :company => 'GenePoint'
# => #<Force::Collection ...>
```

* * *

### Streaming

Force supports the [Streaming API](http://wiki.developerforce.com/page/Getting_Started_with_the_Force.com_Streaming_API), and makes implementing
pub/sub with Salesforce a trivial task:

```ruby
# Force uses faye as the underlying implementation for CometD.
require 'faye'

# Initialize a client with your username/password/oauth token/etc.
client = Force.new :username => 'foo',
  :password       => 'bar',
  :security_token => 'security token'
  :client_id      => 'client_id',
  :client_secret  => 'client_secret'

# Create a PushTopic for subscribing to Account changes.
client.create! 'PushTopic', {
  ApiVersion: '23.0',
  Name: 'AllAccounts',
  Description: 'All account records',
  NotifyForOperations: 'All',
  NotifyForFields: 'All',
  Query: "select Id from Account"
}

EM.run {
  # Subscribe to the PushTopic.
  client.subscribe 'AllAccounts' do |message|
    puts message.inspect
  end
}
```

Boom, you're now receiving push notifications when Accounts are
created/updated.

_See also: http://www.salesforce.com/us/developer/docs/api_streaming/index.htm_

* * *

### Caching

The gem supports easy caching of GET requests (e.g. queries):

```ruby
# rails example:
client = Force.new cache: Rails.cache

# or
Force.configure do |config|
  config.cache = Rails.cache
end
```

If you enable caching, you can disable caching on a per-request basis by using
.without_caching:

```ruby
client.without_caching do
  client.query('select Id from Account')
end
```

* * *

### Logging/Debugging/Instrumenting

You can easily inspect what Force is sending/receiving by setting
`Force.log = true`.

```ruby
Force.log = true
client = Force.new.query('select Id, Name from Account')
```

Another awesome feature about force is that, because it is based on
Faraday, you can insert your own middleware. For example, if you were using
Force in a rails app, you can setup custom reporting to
[Librato](https://github.com/librato/librato-rails) using ActiveSupport::Notifications:

```ruby
client = Force.new do |builder|
  builder.insert_after Force::Middleware::InstanceURL,
    FaradayMiddleware::Instrumentation, name: 'request.salesforce'
end

# config/initializers/notifications.rb
ActiveSupport::Notifications.subscribe('request.salesforce') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Librato.increment 'api.salesforce.request.total'
  Librato.timing 'api.salesforce.request.time', event.duration
end
```

## Force.com Canvas

You can use Force to decode signed requests from Salesforce. See [the example app](https://gist.github.com/4052312).

## Tooling API

To use the [Tooling API](http://www.salesforce.com/us/developer/docs/api_toolingpre/api_tooling.pdf),
call `Force.tooling` instead of `Force.new`:

```ruby
client = Force.tooling(...)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[Force::Collection]: https://github.com/ejholmes/force/blob/master/lib/force/collection.rb "Force::Collection"
