module ParamDoc
  @type_readables = {
    Integer => 'integer',
    Float => 'number',
    String => 'string',
    Array => 'array',
    Hash => 'object'
  }.freeze

  class << self
    def readable_type(type)
      return @type_readables[type] if @type_readables.key?(type)

      return type.to_s
    end
  end
end
