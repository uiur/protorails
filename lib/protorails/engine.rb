require 'zeitwerk'
require 'protorails/routing'

module Protorails
  class Configuration
    attr_accessor :proto_dir, :proto_gen_dir
    def initialize(*)
      @proto_dir = 'app/protos'
      @proto_gen_dir = 'app/gens'
    end
  end

  @config = Configuration.new
  class << self
    attr_reader :config
  end

  class ProtobufInflector < ::Zeitwerk::Inflector
    def camelize(basename, abspath)
      if basename =~ /\A.*(_pb|_twirp)$/
        basename.sub(/(_pb|_twirp)$/, '').camelize
      else
        super
      end
    end
  end

  class Engine < ::Rails::Engine
    initializer 'protobuf_reloader' do |app|
      original_pool = Google::Protobuf::DescriptorPool.generated_pool
      Google::Protobuf::DescriptorPool.class_eval do
        class <<self
          def generated_pool
            @generated_pool ||= new
          end

          def generated_pool=(pool)
            @generated_pool = pool
          end
        end
      end
      Google::Protobuf::DescriptorPool.generated_pool = original_pool


      require 'google/protobuf/well_known_types'
      app.reloader.before_class_unload do
        Google::Protobuf::DescriptorPool.generated_pool = nil
        $VERBOSE = nil
        %w[
          google/protobuf/any_pb
          google/protobuf/duration_pb
          google/protobuf/field_mask_pb
          google/protobuf/struct_pb
          google/protobuf/timestamp_pb
          google/protobuf/well_known_types
        ].each do |file|
          load file
        end
        $VERBOSE = true
      end
    end

    initializer 'protobuf_zeitwerk' do
      Rails.autoloaders.each do |autoloader|
        autoloader.inflector = ProtobufInflector.new
        autoloader.ignore Rails.root.join(::Protorails.config.proto_gen_dir, '**', '*_service_pb.rb').to_s
      end
    end

    rake_tasks do
      load 'tasks/protorails_tasks.rake'
    end

  end
end
