# frozen_string_literal: true

module Meta
  module Utils
    class RouteDSLBuilders
      class << self
        def merge_meta_options(options1, options2)
          final_options = (options1 || {}).merge(options2 || {})
          if options1[:parameters] && options2[:parameters]
            final_options[:parameters] = options1[:parameters].merge(options2[:parameters])
          end
          if options1[:request_body].is_a?(Meta::JsonSchema::ObjectSchema) && options2[:request_body].is_a?(Meta::JsonSchema::ObjectSchema)
            final_options[:request_body] = options1[:request_body].merge_other_properties(options2[:request_body].properties)
          end
          if options1[:responses] && options2[:responses]
            final_options[:responses] = options1[:responses].merge(options2[:responses])
          end
          final_options
        end

        def merge_callbacks(parent_callbacks, current_callbacks)
          # 合并父级传递过来的 callbacks，将 before 和 around 放在前面，after 放在后面
          parent_before = parent_callbacks.filter { |cb| cb[:lifecycle] == :before || cb[:lifecycle] == :around }
          parent_after = parent_callbacks.filter { |cb| cb[:lifecycle] == :after }
          parent_before + current_callbacks + parent_after
        end
      end
    end
  end
end
