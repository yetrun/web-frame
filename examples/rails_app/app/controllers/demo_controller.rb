class DemoController < ApplicationController
  def index
  end

  def show
  end

  params do
    param :user, required: true do
      param :name, type: 'string', default: 'Jim'
      param :age, type: 'integer', default: 18
      param :foo, param: false
    end
  end
  def parse_params
    render json: { params: params, raw_params: raw_params }
  end

  status 200 do
    expose :user, required: true do
      expose :name, type: 'string', default: 'Jim'
      expose :age, type: 'integer', default: 18
    end
  end
  status 201 do
    expose :user, required: true do
      expose :name, type: 'string', default: 'Jack'
      expose :age, type: 'integer', default: 20
    end
  end
  def render_hash
    render json_on_schema: { 'user' => params[:user].to_unsafe_hash }, status: params[:status] || 200, scope: 'foo'
  end

  status 200 do
    expose :user, required: true do
      expose :name, type: 'string', default: 'Jim'
      expose :age, type: 'integer', default: 18
    end
  end
  def render_object
    user = Object.new
    def user.name; 'Jim'; end
    def user.age; 18; end
    render json_on_schema: { 'user' => user }
  end

  status 200 do
    expose :user, required: true do
      expose :a, value: -> { @a }
      expose :b, scope: 'foo'
      expose :c, scope: 'bar'
      expose :d, default: 'd', render: false
    end
  end
  def render_with_options
    @a = 'aa'
    render json_on_schema: { 'user' => params[:user].to_unsafe_hash }, scope: 'foo'
  end
end
