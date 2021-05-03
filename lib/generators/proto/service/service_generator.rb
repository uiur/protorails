module Proto
  module Generators
    class ServiceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      argument :actions, type: :array, default: []
      class_option :package, type: :string

      def create_proto_files
        template 'service.proto', Rails.root.join(Protorails.config.proto_dir, package_dir, "#{destination_name}.proto")
        rpc_actions.each do |action|
          [action.request_name, action.response_name].each do |name|
            @message_name = name
            template 'message.proto', Rails.root.join(Protorails.config.proto_dir, package_dir, "#{name.underscore}.proto")
          end
        end
      end

      private

      def package_name
        options['package'] || default_package_name
      end

      def default_package_name
        [application_name, service_name.underscore].join('.')
      end

      def service_name
        class_name
      end

      def destination_name
        "#{service_name.underscore}_service"
      end

      class RpcAction
        attr_reader :name
        def initialize(name:)
          @name = name
        end

        def request_name
          name + "Request"
        end

        def response_name
          name + 'Response'
        end
      end
      def rpc_actions
        actions.map do |action_name|
          RpcAction.new(name: action_name.camelize)
        end
      end

      def application_name
        Rails.application.class.module_parent.name.underscore
      end

      def package_dir
        package_name.split('.').join('/')
      end

      def import_proto_files
        rpc_actions
          .flat_map do |rpc|
            [rpc.request_name, rpc.response_name]
          end
          .map do |name|
            (package_dir.present? ? package_dir + '/' : '') + "#{name.underscore}.proto"
          end
      end
    end
  end
end
