require "uuid"
require "zlib"
require "cgi"

module OmniAuth
  module Strategies
    class RealMe
      class AuthRequest
        def create(settings, relayState=nil)
          
          #Create unique identifier
          uuid = "_" + UUID.new.generate
          
          #Set timestamp
          time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

          #CCB: replace
          # <saml:AuthnContextClassRef>urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:LowStrength</saml:AuthnContextClassRef>
          # with
          # urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:ModStrength
          request = <<-EOF
            <samlp:AuthnRequest xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
              xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
              AssertionConsumerServiceIndex="#{settings[:assertion_consumer_service_index]}"
              Destination="#{settings[:idp_sso_target_url]}"
              ID="#{uuid}"
              IssueInstant="#{time}"
              Version="2.0"
              ForceAuthn="true">
              <saml:Issuer>#{settings[:issuer]}</saml:Issuer>
              <samlp:NameIDPolicy
                AllowCreate="true"
                Format="#{settings[:name_identifier_format]}"></samlp:NameIDPolicy>
              <samlp:RequestedAuthnContext>
                <saml:AuthnContextClassRef>urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:LowStrength</saml:AuthnContextClassRef>
              </samlp:RequestedAuthnContext>
            </samlp:AuthnRequest>
            EOF
          deflated_request  = Zlib::Deflate.deflate(request, 9)[2..-5]
          base64_request    = [deflated_request].pack('m')
          encoded_request   = CGI.escape(base64_request)
          request_params    = "SAMLRequest=" + encoded_request
          request_params    << "&RelayState=" + relayState if relayState
          request_params    << '&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1'

          #sign
          pkey_rsa = OpenSSL::PKey::RSA.new(File.open(settings[:sp_pem]))

          sig = pkey_rsa.sign(OpenSSL::Digest::SHA1.new, request_params)

          #base64 & urlendcode
          request_params << "&Signature=#{CGI.escape(Base64.encode64(sig))}"

          settings[:idp_sso_target_url] + "?" + request_params
        end
      end
    end
  end
end
