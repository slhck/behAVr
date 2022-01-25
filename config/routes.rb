Rails.application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#index'

  get 'home/about' => 'home#about'

  get 'changelanguage' => 'users#changelanguage'

  get 'admin/index' => 'admin#index'

  resources :experiments, only: [:index, :show] do
    member do
      get 'introduction'           # static pages for experiment parts
      get 'sequencelist'           # static pages for experiment parts
      get 'outro'                  # static pages for experiment parts
      get 'finished'               # static pages for experiment parts

      post 'join'                  # initially join the experiment
      post 'complete_introduction' # to start the experiment after the pre-questionnaire
      post 'finish'                # to finish the main part of the experiment
      post 'complete_outro'        # to complete the experiment after the post-questionnaire
      post 'unjoin'                # cancel the experiment
    end

    resources :test_sequences, only: [] do
      get 'watch'
      get 'rate'
    end

  end

  resources :sequence_results, only: [:index, :show] do
    get 'new_ratings'
    post 'save_ratings'

    resources :behavior_events, only: [:index, :create]
  end


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
