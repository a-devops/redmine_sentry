module RedmineSentry
  module ApplicationControllerPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)  
  
      base.class_eval do
        before_action :set_raven_context
      end
    end
  
    module ClassMethods
    end
    
    module InstanceMethods
      def set_raven_context
        Raven.user_context(id: session[:current_user_id]) # or anything else in session
        Raven.extra_context(params: params.to_unsafe_h, url: request.url)
      end
    end
  
  end
end
