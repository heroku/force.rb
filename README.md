# Force

**PLEASE NOTE. THIS LIBRARY IS NO LONGER BEING MAINTAINED.**

Please use the original version instead: 

[https://github.com/ejholmes/restforce](https://github.com/ejholmes/restforce)

That version is being actively maintained.

**_______________________________________________________**

_A ruby gem for the [Salesforce REST api](http://www.salesforce.com/us/developer/docs/api_rest/index.htm)._

## Features

- A clean and modular architecture using [Faraday middleware](https://github.com/technoweenie/faraday) and [Hashie::Mash](https://github.com/intridea/hashie/tree/v1.2.0)'d responses.
- Support for interacting with multiple users from different orgs.
- Support for parent-to-child relationships.
- Support for aggregate queries.
- Support for the [Streaming API](#streaming)
- Support for blob data types.
- Support for GZIP compression.
- Support for [custom Apex REST endpoints](#custom-apex-rest-endpoints).
- Support for dependent picklists.
- Support for decoding [Force.com Canvas](http://www.salesforce.com/us/developer/docs/platform_connectpre/canvas_framework.pdf) signed requests. (NEW!)

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

#### OAuth Token Authentication

```ruby
client = Force.new :instance_url => 'xx.salesforce.com',
                   :oauth_token => '...'
```

Although the above will work, you'll probably want to take advantage of the
(re)authentication middleware by specifying a refresh token, client id and client secret:

```ruby
client = Force.new :instance_url => 'xx.salesforce.com',
                   :oauth_token => '...',
                   :refresh_token => '...',
                   :client_id => '...',
                   :client_secret => '...'
```

#### Username/Password authentication

If you prefer to use a username and password to authenticate:

```ruby
client = Force.new :username => 'user@example.com',
                   :password => '...',
                   :security_token => '...',
                   :client_id => '...',
                   :client_secret => '...'
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
client = Force.new :proxy_uri => 'http://proxy.example.com:123'
```

This paramter also will accept `http://user@password:proxy.example.com:123` or using the environemnt variable `PROXY_URI`.

#### Sandbox Orgs

You can connect to sandbox orgs by specifying a host. The default host is
`login.salesforce.com`:

```ruby
client = Force.new :host => 'test.salesforce.com'
```
The host can also be set with the environment variable `SALESFORCE_HOST`.

#### Global Configuration

You can set any of the options passed into Force.new globally:

```ruby
Force.configure do |config|
  config.client_id = 'foo'
  config.client_secret = 'bar'
end
```

---

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
client.create('Account', Name: 'Foobar Inc.') # => '0016000000MRatd'
```

### update

```ruby
client.update('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp') # => true
```

### upsert

```ruby
client.upsert('Account', 'External__c', External__c: 12, Name: 'Foobar') # => true
```

### destroy

```ruby
client.destroy('Account', '0016000000MRatd') # => true
```

> All the CRUD methods (`create`, `update`, `upsert`, `destroy`) have equivalent methods with a ! at the end (`create!`, `update!`, `upsert!`, `destroy!`), which can be used if you need to do some custom error handling. The bang methods will raise exceptions, while the
non-bang methods will return false in the event that an exception is raised.

### describe

```ruby
client.describe # => { ... }
client.describe('Account') # => { ... }
```

### describe_layouts

```ruby
client.describe_layout('Account') # => { ... }
client.describe_layouts('Account', '012E0000000RHEp') # => { ... }
```

### picklist_values

```ruby
client.picklist_values('Account', 'Type') # => [#<Force::Mash label="Prospect" value="Prospect">]

# Given a custom object named Automobile__c
#   with picklist fields Model__c and Make__c,
#   where Model__c depends on the value of Make__c.
client.picklist_values('Automobile__c', 'Model__c', :valid_for => 'Honda')
# => [#<Force::Mash label="Civic" value="Civic">, ... ]
```

---

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

### File Uploads

Using the new [Blob Data](http://www.salesforce.com/us/developer/docs/api_rest/Content/dome_sobject_insert_update_blob.htm) api feature (500mb limit):

```ruby
image = Force::UploadIO.new(File.expand_path('image.jpg', __FILE__), 'image/jpeg')
client.create 'Document', FolderId: '00lE0000000FJ6H',
                          Description: 'Document test',
                          Name: 'My image',
                          Body: image)
```

Using base64-encoded data _(37.5mb limit)_:

```ruby
data = Base64::encode64(File.read('image.jpg')
client.create 'Document', FolderId: '00lE0000000FJ6H',
                          Description: 'Document test',
                          Name: 'My image',
                          Body: data)
```

> See also: http://www.salesforce.com/us/developer/docs/api_rest/Content/dome_sobject_insert_update_blob.htm

### Downloading Attachments

Force also makes it incredibly easy to download Attachments:

```ruby
attachment = client.query('select Id, Name, Body from Attachment').first
File.open(attachment.Name, 'wb') { |f| f.write(attachment.Body) }
```

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

...then you could query the cases using Force:

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

### Logging / Debugging / Instrumenting

You can inspect what Force is sending/receiving by setting
`Force.log = true`.

```ruby
Force.log = true
client = Force.new.query('select Id, Name from Account')
```

Another awesome feature about force is that, because it is based on Faraday, you can insert your own middleware.

For example, if you were using Force in a Rails app, you can setup custom reporting to [Librato](https://github.com/librato/librato-rails) using ActiveSupport::Notifications:

```ruby
client = Force.new do |builder|
  builder.insert_after Force::Middleware::InstanceURL,
                       FaradayMiddleware::Instrumentation, name: 'request.salesforce'
end
```

#### config/initializers/notifications.rb

```ruby
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

## Security note

Always sanitize your raw SOQL queries. To avoid SQL-injection (in this case, [SOSQL-injection](https://developer.salesforce.com/page/Secure_Coding_SQL_Injection)) attacks. Given the syntax similarities between SQL and SOQL, [Salesforce recommends using ActiveRecord's sanitization methods](https://developer.salesforce.com/page/Secure_Coding_SQL_Injection#Ruby_on_Rails).

---

## Contact

- Scott Persinger <scottp@heroku.com>

## License

Force is available under the MIT license. See the LICENSE file for more info.
