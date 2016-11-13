require "ly/hotel/version"
require "digest/md5"
require "active_support/core_ext/hash/conversions"
require "uri"
require "net/http"

module Ly
  module Hotel
    class Api
      attr_accessor :req_xml
      attr_accessor :resp_xml
      
      def initialize(account_id, password, api_host, version = "20111128102912")
        @account_id = account_id
        @password = password
        @api_host = api_host
        @version = version
      end
      
      def request(handler, service_name, body = {}, timeout = 7)
        request = {
          "header" => {
            "version" => @version,
            "accountID" => @account_id,
            "serviceName" => service_name,
            "digitalSign" => digital_sign(service_name, req_time = req_time()),
            "reqTime" => req_time
          },
          "body" => body
        }
        @req_xml = request.to_xml(root: 'request', indent: 0, skip_types: true)
        uri = URI.parse "%s/handlers/%sHandler.ashx" % [@api_host, handler]
        resp = Net::HTTP.start(uri.hostname, uri.port) do |http|
          req = Net::HTTP::Post.new(uri, "Content-Type" => "text/xml; charset=UTF-8")
          req.body = @req_xml
          http.read_timeout = timeout
          http.request(req)
        end
        @resp_xml = resp.body.force_encoding("UTF-8")
        response = Hash.from_xml(@resp_xml)
        raise Error.new(response["response"]["header"]["rspDesc"], response["response"]["header"]["rspCode"]) unless response["response"]["header"]["rspCode"] == "0000"
        response['response']['body']
      end
      
      private
        def req_time(time = Time.now)
          time.getgm.getlocal("+08:00").strftime("%Y-%m-%d %H:%M:%S.%L")
        end
        
        def digital_sign(service_name, req_time = req_time())
          token = {
            "AccountID" => @account_id,
            "ReqTime" => req_time,
            "ServiceName" => service_name,
            "Version" => @version
          }
          md5 = Digest::MD5.new
          md5.update token.map { |k, v| "#{k}=#{v}" }.join("&") << @password
          md5.hexdigest
        end
    end
    
    class Error < StandardError
      attr_reader :code
      
      def initialize(message, code = nil)
        super(message)
        @code = code
      end
    end
  end
end
