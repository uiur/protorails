class Protorails::BaseController < ActionController::Metal
  include ::ActionController::Rescue
  include ::AbstractController::Callbacks

  def process_action(*)
    respond_with_rpc do
      super
    end
  end

  protected

  class << self
    delegate :rpcs, to: :rpc_service
    attr_reader :rpc_service
    def service(rpc_service)
      @rpc_service = rpc_service
    end
  end

  delegate :service_full_name, to: :rpc_service
  def rpc_service
    self.class.rpc_service
  end

  def respond_with_rpc
    rpc_request
    output =
      begin
        yield
      rescue ::ActiveRecord::RecordNotFound
        Twirp::Error.new(:not_found, 'Record is not found')
      end

    return if performed?

    output =
      case output
      when env[:output_class], Twirp::Error
        output
      when Hash
        env[:output_class].descriptor.each do |f|
          unless f.type == :message
            unless output.has_key?(f.name.to_sym)
              raise "#{env[:output_class].name} expect `#{f.name}` field, but it's not included"
            end
          end
        end

        env[:output_class].new(output)
      else
        Twirp::Error.internal("Handler method expected to return one of #{env[:output_class].name}, Hash or Twirp::Error, but returned #{output.class.name}.")
      end

    if output.is_a?(Twirp::Error)
      error_response(output)
    else
      response.headers['Content-Type'] = env[:content_type]
      self.response_body = ::Twirp::Encoding.encode(output, env[:output_class], env[:content_type])
    end
  end

  def error_response(twerr)
    response.headers['Content-Type'] = ::Twirp::Encoding::JSON
    self.status = Twirp::ERROR_CODES_TO_HTTP_STATUS[twerr.code]
    self.response_body = ::Twirp::Encoding.encode_json(twerr.to_h)
  end

  def rpc_request
    @rpc_request ||= route_request
  end

  def route_request
    rack_request = request

    if rack_request.request_method != "POST"
      return route_err(:bad_route, "HTTP request method must be POST", rack_request)
    end

    content_type = rack_request.get_header("CONTENT_TYPE")
    if !::Twirp::Encoding.valid_content_type?(content_type)
      return route_err(:bad_route, "Unexpected Content-Type: #{content_type.inspect}. Content-Type header must be one of #{Encoding.valid_content_types.inspect}", rack_request)
    end
    env[:content_type] = content_type

    path_parts = rack_request.fullpath.split("/")
    if path_parts.size < 3 || path_parts[-2] != self.service_full_name
      return route_err(:bad_route, "Invalid route. Expected format: POST {BaseURL}/#{self.full_name}/{Method}", rack_request)
    end
    method_name = path_parts[-1]

    base_env = self.class.rpcs[method_name]
    if !base_env
      return route_err(:bad_route, "Invalid rpc method #{method_name.inspect}", rack_request)
    end
    env.merge!(base_env) # :rpc_method, :input_class, :output_class

    input = nil
    begin
      input = ::Twirp::Encoding.decode(rack_request.body.read, env[:input_class], content_type)
    rescue => e
      error_msg = "Invalid request body for rpc method #{method_name.inspect} with Content-Type=#{content_type}"
      if e.is_a?(Google::Protobuf::ParseError)
        error_msg += ": #{e.message.strip}"
      end
      return route_err(:malformed, error_msg, rack_request)
    end
  end

  def route_err(code, msg, req)
    Twirp::Error.new(code, msg, twirp_invalid_route: "#{req.request_method} #{req.fullpath}")
  end

  def env
    @env ||= {}
  end
end
