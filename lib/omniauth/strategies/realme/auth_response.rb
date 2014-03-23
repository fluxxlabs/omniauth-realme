require "time"
require "savon"
require 'nokogiri'
require 'uuid'

module OmniAuth
  module Strategies
    class RealMe
      class AuthResponse

        attr_accessor :settings, :response, :response_doc

        def initialize(saml_art, settings)
          raise ArgumentError.new("SAML Artifact cannot be nil") if saml_art.nil?
          self.settings = settings
          p "CCB #{saml_art}"
          #unpack SAML artifact
          type, index, source_id, message_handle = saml_art.unpack('m')[0].unpack('nna20a20')
          raise ArgumentError.new("Index must be a number") unless index.to_i.is_a?(Integer)

          #Configure SOAP with correct endpoint and namespace
          client = Savon::Client.new do
            wsdl.endpoint = idp_endpoint(index)
            wsdl.namespace = "http://soap.example.com"
          end
          
          #Create UUID
          uuid = "_" + UUID.new.generate
          
          #Set timestamp
          time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
          
          self.response = client.request "http://www.oasis-open.org/committees/security" do
            http.auth.ssl.cert_file = settings[ :mutual_ssl_sp_cer]
            http.auth.ssl.cert_key_file = settings[:mutual_ssl_sp_pem]
            puts "About to use ca_cer"
            Rails.logger.info "About to use ca_cer"
            if settings[:ca_cert]   
              ssl_cert_file = settings[:ca_cert]       
              puts "USING SSL CERT FILE: #{ssl_cert_file}" 
              Rails.logger.info "USING SSL CERT FILE: #{ssl_cert_file}"
              http.auth.ssl.ca_cert_file = ssl_cert_file
              http.auth.ssl.verify_mode = :peer
            else
              http.auth.ssl.verify_mode = :none
            end

            soap.xml = <<-EOF
            <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
              <SOAP-ENV:Body>
                <samlp:ArtifactResolve
                  xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                  xmlns="urn:oasis:names:tc:SAML:2.0:assertion"
                  ID="#{uuid}"
                  Version="2.0"
                  IssueInstant="#{time}">
                  <Issuer>#{settings[:issuer]}</Issuer>
                  <samlp:Artifact>#{saml_art}</samlp:Artifact>
                </samlp:ArtifactResolve>
              </SOAP-ENV:Body>
            </SOAP-ENV:Envelope>
            EOF
          end
          puts "RESPONSE: #{self.response.to_xml}"
          Rails.logger.info "RESPONSE: #{self.response.to_xml}"
          self.response_doc = Nokogiri::XML(self.response.to_xml)
        end
        
        def successful?
          status == "Success"
        end

        #Extract NameID from response
        def name_id
          self.response_doc.xpath("//saml:Subject/saml:NameID", 'saml' => "urn:oasis:names:tc:SAML:2.0:assertion").text
        end

        #Extract StatusCode from response
        def status
          self.response_doc.xpath("//samlp:Response/samlp:Status//samlp:StatusCode/@Value", 'samlp' => "urn:oasis:names:tc:SAML:2.0:protocol").last.text.split(":").last
        end

        #Use index to determine which endpoint to use in the RealMe IdP metadata
        def idp_endpoint(index)
          idp_metadata_xml = File.open(settings[:idp_metadata])
          metadata_doc = Nokogiri::XML(idp_metadata_xml)
          metadata_doc.xpath("//md:ArtifactResolutionService[@index='#{index}']/@Location", 'md' => "urn:oasis:names:tc:SAML:2.0:metadata").text
        end
      end
    end
  end
end