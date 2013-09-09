FacebookStatistic::Application.routes.draw do
  get "sessions/create"

  get '/auth/:provider/callback', to: 'sessions#create'
end
