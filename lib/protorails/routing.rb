module ActionDispatch::Routing
  class Mapper
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
        post "/twirp/#{service.service_full_name}/#{name}", {
          controller: service.service_full_name.split('.')[-1].downcase.pluralize,
          action: name.underscore,
          format: false
        }
      end
    end
  end
end
