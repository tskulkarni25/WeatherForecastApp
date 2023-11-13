Rails.application.routes.draw do
  get 'forecast/index'
  root 'forecast#index'
end
