# OmniAuth RealMe

A New Zealand Government RealMe strategy for OmniAuth.

The single most important document that will aid you in integration with RealMe is the "RealMe logon service Integrator's Guide for SAML v2.0" available from the Department of Internal Affairs RealMe team.

Using the realme strategy in your Rails application:

in `Gemfile`:

```ruby
gem 'omniauth-realme'
```

and in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :realme,
  	:assertion_consumer_service_index => 0,
    :issuer                           => "issuer_url",
    :sp_pem                           => "path_to_sp_pem_file",
    :idp_metadata                     => "path_to_idp_metadata_xml_file",
    :idp_sso_target_url               => "target_url",
    :name_identifier_format           => "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
    :mutual_ssl_sp_pem                => "path_to_mutual_ssl_sp_pem",
    :mutual_ssl_sp_cer                => "path_to_mutual_ssl_sp_cer"
end
```

Add the following to your routes.rb

```ruby
match '/auth/:provider/callback' => 'controller#action'
match '/auth/failure' => "controller#action"
```

You can substitute the 'controller' and 'action' placeholders for the controller and action specific to your application.

In the callback action, you then will have access to hash with information about the user. You can access this hash at the controller level via:
```ruby
request.env['omniauth.auth']
```


or in other ruby environments:

```ruby
require 'omniauth'
use OmniAuth::Strategies::RealMe,
  :assertion_consumer_service_index => 0,
  :issuer                           => "issuer_url",
  :sp_pem                           => "path_to_sp_pem_file",
  :idp_metadata                     => "path_to_idp_metadata_xml_file",
  :idp_sso_target_url               => "target_url",
  :name_identifier_format           => "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
  :mutual_ssl_sp_pem                => "path_to_mutual_ssl_sp_pem",
  :mutual_ssl_sp_cer                => "path_to_mutual_ssl_sp_cer"
```

## Settings
* `:assertion_consumer_service_index` - The index of the service you are consuming, this refers to the AssertionConsumerService as configured in your Service Provider Metadata supplied to RealMe. The index is 0 based, so the value will be 0 if you only have one Consumer configured **Required**.

* `:issuer` - The name of your application. RealMe requires this to establish the identity of the service provider requesting the login. **Required**.

* `:sp_pem` - The location of the file containing your private key used for the request. **Required**.
	
* `:idp_metadata` - The location of the RealMe metadata file.  **Required**.

* `:idp_sso_target_url` - The URL to which the authentication request should be sent. This would be on the identity provider. **Required**.

* `:name_identifier_format` - Describes the format of the uid returned by RealMe. **Required**.

* `:mutual_ssl_sp_pem` - The location of the file containing your private key for mutual SSL setup. **Required**.

* `:mutual_ssl_sp_cer` - The location of the file containing your certificate for mutual SSL setup. **Required**.


## License

Copyright (c) 2011-2012 [National Library of New Zealand](http://www.natlib.govt.nz/).  
All rights reserved. Released under the MIT license.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
