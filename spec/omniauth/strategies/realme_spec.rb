require File.expand_path('../../../spec_helper', __FILE__)
require "base64"
require "uuid"
require "zlib"
require "cgi"
require "savon"
require 'Nokogiri'

describe OmniAuth::Strategies::RealMe, :type => :strategy do
  
  include OmniAuth::Test::StrategyTestCase
  
  def strategy
    [OmniAuth::Strategies::RealMe, {
      :assertion_consumer_service_index => 1,
      :issuer                           => "https://sample-service-provider.org.nz/mts2/sp",
      :sp_pem                           => File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_sp.pem'),
      :idp_metadata                     => File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_idp_metadata.xml'),
      :idp_sso_target_url               => "https://sample-service-provider.org.nz/controller/SSO",
      :name_identifier_format           => "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
      :mutual_ssl_sp_pem                => File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_mutualssl_saml_sp.pem'),
      :mutual_ssl_sp_cer                => File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_mutualssl_saml_sp.cer')
    }]
  end

  describe 'GET /auth/realme' do
    before do
      get '/auth/realme'
    end

    it 'should get the realme login page' do
      last_response.should be_redirect
    end
  end

  describe 'POST /auth/realme/callback with a SAMLArt parameter' do
    before do
      stub_request(:post, "https://logon2.i.govt.nz:44320/soap/services/SAMLMessageProcessor/AP").
        with(:body => "            <SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"> \n              <SOAP-ENV:Body>\n                <samlp:ArtifactResolve \n                  xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"\n                  xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" \n                  ID=\"__1234567890\"\n                  Version=\"2.0\"\n                  IssueInstant=\"2011-08-31T07:11:58Z\"> \n                  <Issuer>https://sample-service-provider.org.nz/mts2/sp</Issuer> \n                  <samlp:Artifact></samlp:Artifact>\n                </samlp:ArtifactResolve>\n              </SOAP-ENV:Body>\n            </SOAP-ENV:Envelope>\n",
             :headers => {'Accept'=>'*/*', 'Content-Length'=>'720', 'Content-Type'=>'text/xml;charset=UTF-8', 'Soapaction'=>'"http://www.oasis-open.org/committees/security"'}).
        to_return(:status => 200, :body => File.open(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_failure.xml')), :headers => {})
      post '/auth/realme/callback'
    end
    
    it 'should fail' do
      last_response.should be_redirect
      last_response.location.should == '/auth/failure?message=invalid_argument'
    end
  end
  
  describe 'POST /auth/realme/callback with a SAMLArt parameter' do
    before do
      UUID.stub_chain(:new, :generate).and_return("_1234567890")
      Time.stub(:now).and_return(Time.parse("2011-08-31T07:11:58Z"))
    end
    
    it 'should process the response with a valid SAMLArt and request' do
      stub_request(:post, "https://logon2.i.govt.nz:44320/soap/services/SAMLMessageProcessor/AP").
        with(:body => "            <SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n              <SOAP-ENV:Body>\n                <samlp:ArtifactResolve\n                  xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"\n                  xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\"\n                  ID=\"__1234567890\"\n                  Version=\"2.0\"\n                  IssueInstant=\"2011-08-31T07:11:58Z\">\n                  <Issuer>https://sample-service-provider.org.nz/mts2/sp</Issuer>\n                  <samlp:Artifact>AAQAAeaxzBXW4zxG7znSTbbe67VLVFexU/By7V/C8MtCtrHTJ/eYJPNbSRU=</samlp:Artifact>\n                </samlp:ArtifactResolve>\n              </SOAP-ENV:Body>\n            </SOAP-ENV:Envelope>\n",
             :headers => {'Accept'=>'*/*', 'Content-Length'=>'715', 'Content-Type'=>'text/xml;charset=UTF-8', 'Soapaction'=>'"http://www.oasis-open.org/committees/security"'}).
        to_return(:status => 200, :body => File.open(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_success.xml')), :headers => {})
      get '/auth/realme/callback?SAMLart=AAQAAeaxzBXW4zxG7znSTbbe67VLVFexU%2FBy7V%2FC8MtCtrHTJ%2FeYJPNbSRU%3D'
      
      last_response.body.should == "true"
    end
    
    it 'should process the response for errors' do
      stub_request(:post, "https://logon2.i.govt.nz:44320/soap/services/SAMLMessageProcessor/AP").
        with(:body => "            <SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n              <SOAP-ENV:Body>\n                <samlp:ArtifactResolve\n                  xmlns:samlp=\"urn:oasis:names:tc:SAML:2.0:protocol\"\n                  xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\"\n                  ID=\"__1234567890\"\n                  Version=\"2.0\"\n                  IssueInstant=\"2011-08-31T07:11:58Z\">\n                  <Issuer>https://sample-service-provider.org.nz/mts2/sp</Issuer>\n                  <samlp:Artifact>AAQAAeaxzBXW4zxG7znSTbbe67VLVFexU/By7V/C8MtCtrHTJ/eYJPNbSRU=</samlp:Artifact>\n                </samlp:ArtifactResolve>\n              </SOAP-ENV:Body>\n            </SOAP-ENV:Envelope>\n",
              :headers => {'Accept'=>'*/*', 'Content-Length'=>'715', 'Content-Type'=>'text/xml;charset=UTF-8', 'Soapaction'=>'"http://www.oasis-open.org/committees/security"'}).
        to_return(:status => 200, :body => File.open(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'realme_failure.xml')), :headers => {})
      get '/auth/realme/callback?SAMLart=AAQAAeaxzBXW4zxG7znSTbbe67VLVFexU%2FBy7V%2FC8MtCtrHTJ%2FeYJPNbSRU%3D'
      
      last_response.location.should == "/auth/failure?message=AuthnFailed"
    end
  end
  
end
