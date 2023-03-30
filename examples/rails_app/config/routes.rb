Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  post '/parse_params', to: 'data#parse_params'
  post '/render_hash', to: 'data#render_hash'
  post '/render_object', to: 'data#render_object'
  post '/render_with_options', to: 'data#render_with_options'

  get '/swagger_doc', to: 'swagger#get_spec'
end
