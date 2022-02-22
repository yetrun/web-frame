# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/swagger_doc'
require 'json'
require 'grape-entity'

describe 'SwaggerDocUtil.generate' do
  subject do
    doc = SwaggerDocUtil.generate(app)
    doc[:paths]['/user'][:get][:responses][200][:content]['application/json'][:schema]
  end

  let(:app) do
    app = Class.new(Application)

    the_arguments = arguments
    app.route('/user', :get)
      .if_status(200) {
        expose(*the_arguments)
      }

    app
  end

  let(:entity_class) do
    Class.new(Grape::Entity) do
      expose :name, :age
    end
  end

  describe 'generating responses schema documentation' do
    context '.expose(:key, entity_class)' do
      let(:arguments) { [:user, presenter: entity_class] }

      it {
        is_expected.to eq(
          type: 'object',
          properties: {
            user: {
              type: 'object',
              properties: {
                name: {},
                age: {}
              }
            }
          }
        )
      }
    end

    context '.expose(entity_class)' do
      before { skip('暂不支持将 Grape::Entity 应用在顶层') }

      let(:arguments) { [entity_class] }

      it {
        is_expected.to eq(
          type: 'object',
          properties: {
            name: {},
            age: {}
          }
        )
      }

      context 'with inner nesting entity class' do
        let(:entity_class) do
          inner_entity_class = Class.new(Grape::Entity) do
            expose :name, :age
          end

          Class.new(Grape::Entity) do
            expose :user, using: inner_entity_class
          end
        end

        it {
          is_expected.to eq(
            type: 'object',
            properties: {
              user: {
                type: 'object',
                properties: {
                  name: {},
                  age: {}
                }
              }
            }
          )
        }
      end
    end

    describe 'array type entity class' do
      context 'ExposureScope.entity with `is_array` is true' do
        let(:arguments) { [:user, type: 'array', items: { presenter: entity_class }] }

        it {
          is_expected.to eq(
            type: 'object',
            properties: {
              user: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    name: {},
                    age: {}
                  }
                }
              }
            }
          )
        }
      end

      context 'Grape::Entity.expose with `is_array` is true' do
        let(:arguments) { [:data, presenter: entity_class] }

        let(:entity_class) do
          inner_entity_class = Class.new(Grape::Entity) do
            expose :name, :age
          end

          Class.new(Grape::Entity) do
            expose :user, using: inner_entity_class, documentation: { is_array: true }
          end
        end

        it {
          is_expected.to eq(
            type: 'object',
            properties: {
              data: {
                type: 'object',
                properties: {
                  user: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        name: {},
                        age: {}
                      }
                    }
                  }
                }
              }
            }
          )
        }
      end
    end

    describe 'type and description' do
      context 'declaring type and description in Grape::Entity' do
        let(:arguments) { [:user, presenter: entity_class] }

        let(:entity_class) do
          Class.new(Grape::Entity) do
            expose :name, documentation: { type: 'string', description: '姓名' }
            expose :age, documentation: { type: 'integer', description: '年龄' }
          end
        end

        it {
          is_expected.to eq(
            type: 'object',
            properties: {
              user: {
                type: 'object',
                properties: {
                  name: { type: 'string', description: '姓名' },
                  age: { type: 'integer', description: '年龄' }
                }
              }
            }
          )
        }

        context 'exposing a hash' do
          let(:arguments) { [:data, presenter: entity_class] }

          # HACK: 命名为 user_entity_class
          let(:inner_entity_class) do
            Class.new(Grape::Entity) do
              expose :name
              expose :age
            end
          end

          let(:entity_class) do
            the_inner_entity_class = inner_entity_class
            Class.new(Grape::Entity) do
              expose :user, using: the_inner_entity_class, documentation: { description: '用户' }
            end
          end

          it {
            is_expected.to eq(
              type: 'object',
              properties: {
                data: {
                  type: 'object',
                  properties: {
                    user: {
                      type: 'object',
                      description: '用户',
                      properties: {
                        name: {},
                        age: {}
                      }
                    }
                  }
                }
              }
            )
          }
        end

        context 'exposing a array' do
          let(:arguments) { [:data, presenter: entity_class] }

          let(:inner_entity_class) do
            Class.new(Grape::Entity) do
              expose :name
              expose :age
            end
          end

          let(:entity_class) do
            the_inner_entity_class = inner_entity_class
            Class.new(Grape::Entity) do
              expose :user, using: the_inner_entity_class, documentation: { is_array: true, description: '用户' }
            end
          end

          it {
            is_expected.to eq(
              type: 'object',
              properties: {
                data: {
                  type: 'object',
                  properties: {
                    user: {
                      type: 'array',
                      description: '用户',
                      items: {
                        type: 'object',
                        properties: {
                          name: {},
                          age: {}
                        }
                      }
                    }
                  }
                }
              }
            )
          }
        end
      end

      context 'declaring type and description in EntityScope' do
        let(:arguments) { [:count, { type: 'integer', description: '数量' }] }

        it {
          is_expected.to eq(
            type: 'object',
            properties: {
              count: {
                type: 'integer',
                description: '数量'
              }
            }
          )
        }

        context 'is array' do
          let(:arguments) { [:count, { type: 'array', items: { type: 'integer' }, description: '数量' }] }

          it {
            is_expected.to eq(
              type: 'object',
              properties: {
                count: {
                  type: 'array',
                  description: '数量',
                  items: {
                    type: 'integer'
                  }
                }
              }
            )
          }
        end

        context 'entitying an entity class' do
          let(:arguments) { [:user, presenter: entity_class, description: '用户'] }

          it {
            is_expected.to eq(
              type: 'object',
              properties: {
                user: {
                  type: 'object',
                  description: '用户',
                  properties: {
                    name: {},
                    age: {}
                  }
                }
              }
            )
          }
        end

        context 'entitying an entity class array' do
          let(:arguments) { [:user, type: 'array', items: { presenter: entity_class }, description: '用户数组'] }

          it {
            is_expected.to eq(
              type: 'object',
              properties: {
                user: {
                  type: 'array',
                  description: '用户数组',
                  items: {
                    type: 'object',
                    properties: {
                      name: {},
                      age: {}
                    }
                  }
                }
              }
            )
          }
        end
      end
    end
  end
end
