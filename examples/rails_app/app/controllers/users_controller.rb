class UsersController < ApplicationController
  def index
  end

  def show
  end

  params do
    param :user, required: true do
      param :name, type: 'string', default: 'Jim'
      param :age, type: 'integer', default: 18
    end
  end
  def create
    render json: { params: params, raw_params: raw_params }
  end

  status 200 do
    expose :user, required: true do
      param :name, type: 'string', default: 'Jim'
      param :age, type: 'integer', default: 18
    end
  end
  def update
    render json_on_schema: { 'user' => params[:user].to_unsafe_hash }
  end

  def destroy
  end
end
