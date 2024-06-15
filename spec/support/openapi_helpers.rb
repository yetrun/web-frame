# frozen_string_literal: true

module OpenAPIHelpers
  # 自带验证的 OpenAPI 文档生成
  def generate_openapi_doc(mod)
    doc = mod.to_swagger_doc
    doc[:info][:title] ||= '用于单元测试的 API 文档'
    doc[:info][:version] ||= '0.0.0'
    expect(doc).to be_valid_openapi_document
    doc
  end
end
