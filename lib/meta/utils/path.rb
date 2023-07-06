# frozen_string_literal: true

module Meta
  module Utils
    class Path
      class << self
        # 规范化 path 结构，确保 path 以 '/' 开头，不以 '/' 结尾。
        # TODO: 仅有一个例外，如果 path 为 nil 或空字符串，则返回空字符串 ''.
        def normalize_path(path)
          path = '/' unless path
          path = '/' + path unless path.start_with?('/')
          path = path.delete_suffix('/') if path.end_with?('/')
          path
        end

        # 合并两个 path. 有且只有一个例外，如果 p1 或 p2 其中之一为 '/'，则返回另一个。
        def join(p1, p2)
          p1 = normalize_path(p1)
          p2 = normalize_path(p2)
          return p2 if p1 == ''
          return p1 if p2 == ''
          return normalize_path(p1 + p2)
        end
      end
    end
  end
end
