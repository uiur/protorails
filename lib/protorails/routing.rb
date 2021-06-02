
module Protorails
  module Routing
    module Mapper
      def define_protorails_routes
        proto_gen_dir = Rails.root.join(::Protorails.config.proto_gen_dir)
        service_classes = Dir[proto_gen_dir.join('**', '*_service_*.rb')].sort.map {|path|
          dir = File.dirname(path)
          basename = File.basename(path, '.rb')
          relative_dir = Pathname.new(dir).relative_path_from(proto_gen_dir)
          [
            relative_dir.to_s.classify,
            Rails.autoloaders.main.inflector.camelize(basename, path)
          ].join('::')
        }.uniq.map(&:constantize)

        service_classes.each do |service|
          twirp_service_route(service)
        end
      end

      def twirp_service_route(service)
        service.rpcs.each do |name, _|
          next if has_named_route?(twirp_route_name(service, name))
          twirp_rpc(service, name)
        end
      end

      def twirp_rpc(service, rpc_name, **options)
        rpc_name = rpc_name.to_s.camelize

        post "/twirp/#{service.service_full_name}/#{rpc_name}", {
          controller: service.service_full_name.split('.')[-1].underscore.pluralize,
          action: rpc_name.underscore,
          format: false,
          as: twirp_route_name(service, rpc_name),
        }.merge(options)
      end

      def twirp_route_name(service, rpc_name)
        ['twirp', service.service_full_name.gsub('.', '_'), rpc_name].map(&:underscore).join('__')
      end
    end
  end
end

module ActionDispatch::Routing
  class Mapper
    include ::Protorails::Routing::Mapper
  end
end
