module Proto
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      class_option :package, type: :string

      def create_proto_files
        template 'template.proto', Rails.root.join(Protorails.config.proto_dir, package_dir, "#{message_name.underscore}.proto")
      end

      private

      ProtoField = Struct.new(:name, :type, keyword_init: true)
      class ProtoAssociationField
        attr_reader :association
        def initialize(association)
          @association = association
        end

        def name
          association.name
        end

        def type
          [
            association.collection? ? 'repeated' : nil,
            message_type
          ].compact.join(' ')
        end

        def message_type
          association.klass.name + 'Resource'
        end
      end

      TYPE_TO_PROTO_TYPE = {
        integer: 'int32',
        bigint: 'int64',
        string: 'string',
        uuid: 'string',
        date: 'google.protobuf.Timestamp',
        datetime: 'google.protobuf.Timestamp'
      }.freeze

      def klass
        class_name.constantize
      end

      def proto_fields
        klass.attribute_types.reject {|name, _| name.end_with?('_id') || name.end_with?('_digest') }.map do |name, value_type|
          type_name = TYPE_TO_PROTO_TYPE[value_type.type] || :string
          if value_type.is_a?(ActiveRecord::Enum::EnumType)
            type_name = name.classify
          end
          ProtoField.new(name: name, type: type_name)
        end
      end

      def enum_definitions
        klass.attribute_types.select {|_, type| type.is_a?(ActiveRecord::Enum::EnumType) }.map do |name, type|
          mappings = klass.public_send(name.pluralize)
          [
            name.classify,
            mappings.map do |value, raw_value|
              { name: value.upcase, index: raw_value }
            end
          ]
        end.to_h
      end

      def proto_association_fields
        klass.reflect_on_all_associations.map do |association|
          ProtoAssociationField.new(association)
        end
      end

      def message_name
        "#{class_name}Resource"
      end

      def package_name
        options['package'] || ''
      end

      def package_dir
        package_name.split('.').join('/')
      end

      def import_proto_files
        proto_association_fields.map do |field|
          (package_dir.presence ? package_dir + '/' : '') + "#{field.message_type.underscore}.proto"
        end
      end
    end
  end
end
