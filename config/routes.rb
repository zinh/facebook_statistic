FacebookStatistic::Application.routes.draw do
  get "sessions/create"

  get '/auth/:provider/callback', to: 'sessions#get_messsage_raking'
end
