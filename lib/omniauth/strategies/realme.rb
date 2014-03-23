require 'omniauth'

module OmniAuth
  module Strategies
    class RealMe
      include OmniAuth::Strategy
      autoload :AuthRequest,      'omniauth/strategies/realme/auth_request'
      autoload :AuthResponse,     'omniauth/strategies/realme/auth_response'

      def request_phase
        request = OmniAuth::Strategies::RealMe::AuthRequest.new
        redirect(request.create(options))
      end

      def callback_phase
        begin
          response = OmniAuth::Strategies::RealMe::AuthResponse.new(request.params['SAMLart'], options)    
          @name_id  = response.name_id     
          p "CCB #{request.params.inspect}"     
          return fail!(response.status) unless response.successful?
          super
        rescue ArgumentError => e
          fail!(:invalid_argument, e.message)
        end
      end

      uid { @name_id }
      
    end
  end
end

#OmniAuth.config.add_camelization 'igovt', 'Igovt'
