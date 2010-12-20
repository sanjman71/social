# monkey patch faraday
require 'faraday'

# module Faraday
#   module Adapter
#     class NetHttp < Middleware
#      
#      def call_with_ssl(env)
#        env[:ssl] ||= Hash[]
#        env[:ssl][:verify] = false
#        call_without_ssl(env)
#      end
# 
#      alias_method_chain :call, :ssl 
#     end
#   end
# end