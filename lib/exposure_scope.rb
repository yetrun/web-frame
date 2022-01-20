class ExposureScope
  def initialize(&block)
    @root_exposure = nil
    @exposures = {}

    instance_eval &block if block_given?
  end

  # expose
  # expose(UserEntity)
  # expose(UserEntity, full: true)
  #
  # expose(:user)
  # expose(:user, UserEntity)
  # expose(:user, UserEntity, full: true)
  def expose(key = nil, entity_class = nil, options = nil, &block)
    if key.is_a?(Symbol)
      @exposures[key] = {
        block: block,
        entity_class: entity_class,
        options: options || {}
      }
    else
      entity_class, options = [key, entity_class]

      @root_exposure = {
        block: block,
        entity_class: entity_class,
        options: options || {}
      }
    end
  end

  def generate_json(execution)
    root_hash = {}
    if @root_exposure
      root_hash = generate_with_exposure(execution, @root_exposure) 
      raise 'Root exposure 的结果必须是一个 Hash' unless root_hash.is_a?(Hash)
    end

    exposures_hash = @exposures.transform_values do |exposure|
      generate_with_exposure(execution, exposure)
    end

    JSON.generate(root_hash.merge(exposures_hash))
  end

  def to_schema
    {
      type: 'object',
      properties: @exposures.transform_values do |exposure|
        generate_entity_schema(exposure[:entity_class])
      end
    }
  end

  private

  def generate_with_exposure(execution, exposure)
    value = execution.instance_exec(&exposure[:block])
    value = exposure[:entity_class].represent(value, exposure[:options]) if exposure[:entity_class]
    value = value.as_json if value.respond_to?(:as_json)

    value
  end

  def generate_entity_schema(entity_class)
    {
      type: 'object',
      properties: entity_class.root_exposures.map { |exposure| [exposure.key, {}] }.to_h
    }
  end
end
