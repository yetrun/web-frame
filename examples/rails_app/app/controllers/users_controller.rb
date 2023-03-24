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

  def update
  end

  def destroy
  end
end
