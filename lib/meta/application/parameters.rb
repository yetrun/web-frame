# 仅仅处理 URL、Query、Header 中的参数

module Meta
  class Parameters
    extend Forwardable

    attr_reader :parameters

    def initialize(parameters)
      @parameters = parameters.dup
    end

    def filter(request)
      errors = {}
      final_value = {}

      parameters.each do |name, options|
        schema = options[:schema]
        value = if options[:in] == 'header'
                  schema.filter(request.get_header('HTTP_' + name.to_s.upcase.gsub('-', '_')))
                else
                  schema.filter(request.params[name.to_s])
                end
        final_value[name] = value
      rescue JsonSchema::ValidationError => e
        errors[name] = e.message
      end
      raise Errors::ParameterInvalid.new(errors) unless errors.empty?

      final_value
    end

    def to_swagger_doc
      parameters.map do |name, options|
        property_options = options[:schema].options
        {
          name: name,
          in: options[:in],
          required: property_options.key?(:required) ? property_options[:required] : false,
          description: property_options[:description] || '',
          schema: {
            type: property_options[:type]
          }.compact
        }.compact
      end unless parameters.empty?
    end

    def merge(parameters)
      parameters_hash = parameters.is_a?(Parameters) ? parameters.parameters : parameters
      Parameters.new(self.parameters.merge(parameters_hash))
    end

    def_delegators :parameters, :key?, :empty?
  end
end
