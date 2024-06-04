#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

Rails.application.routes.draw do
  # Engines
  authenticate :user, ->(user) { user.root? } do
    mount GoodJob::Engine => 'good_job'
  end

  devise_for :users,
    only: [:sessions, :registrations],
    controllers: { sessions: "sessions", registrations: "registrations" },
    path: 'accounts'
  # Add "/users/sign_in" route to avoid breaking API clients.
  devise_scope :user do
    post "users/sign_in", to: "sessions#create"
  end

  mount ActionCable.server => '/cable'

  # We need to redirect here, otherwise the devise redirections will take us to
  # the legacy sign up page.
  root to: redirect('/racks')

  resource :interactive_rack_views, only: [], path: '/irv' do
    get :configuration
  end

  resource :interactive_rack_views, only: :show, path: '/racks'
  resources :racks, only: [:show] do
    member do
      get :devices
      get 'instructions/:instruction_id', to: 'racks#instructions', as: :instructions
    end
  end

  scope '/cloud-env' do
    resource :cloud_service_config, path: '/config' do
      member do
        post :send_config, as: 'send', path: 'send'
      end
    end
    resources :cluster_types, path: 'cluster-types', only: [:index], param: :foreign_id do
      resources :clusters, only: [:new, :create]
    end
  end

  resources :users, only: [:index, :edit, :update, :destroy]

  resource :settings, only: [:edit, :update]

  get '/statistics', to: 'statistics#index'

  resources :teams do
    member do
      get :usage_limits
    end
    resources :team_roles, only: [:index, :new, :create]
    resources :invoices, only: [:index, :show] do
      collection do
        get 'draft'
      end
    end
    resources :credit_deposits, only: [:new, :create]
  end

  resources :team_roles, only: [:edit, :update, :destroy]

  resources :key_pairs, only: [:index, :new, :create] do
    collection do
      get '/success', to: 'key_pairs#success'
      delete '/:name', to: 'key_pairs#destroy', as: :delete
    end
  end

  resources :devices, only: [:show] do
    resources :metrics, only: [:index]
  end

  resources :templates, only: [:index, :edit, :update]

  # API routes
  #
  # Some of these have been done in a non-railsy way (you have "posts" where you should have 
  # "puts", missing plurals where we should have plurals... to be tidied up at some point.
  #
  namespace :api do
    ['v1'].each do |version|
      namespace version do

        resources :racks
        resources :templates, only: [:index, :create, :update, :destroy]
        resources :nodes, only: [:create]
        resources :devices, only: [:index, :show, :update, :destroy] do
          resources :metrics, :constraints => { :id => /.*/ }, only: [:show]
        end
        resources :data_source_maps, path: 'data-source-maps', only: [:index]
        resources :teams, only: [:index, :create, :update, :destroy]

        # For use by the interactive rack view
        namespace :irv do
          resources :racks, only: [:index] do
            member do
              post :request_status_change
            end
            collection do 
              get :modified
            end
          end
          resources :nonrack_devices, only: [:index] do
            collection do
              get :modified
            end
          end
          resources :chassis do
            member do
              post :update_position
            end
          end
          resources :devices, only: [] do
            member do
              post :update_slot
              post :request_status_change
            end
          end
          resources :rackview_presets, only: [:index, :create, :update, :destroy]
          resources :metrics, :constraints => { :id => /.*/ }, only: [] do
            member do
              post :show
            end
          end
        end

        resources :metrics, :constraints => { :id => /.*/ }, only: [] do
          get :structure, :on => :collection
        end
        resources :users, only: [:index, :update, :destroy] do
          collection do
            # Endpoint for checking user abilities.
            get :permissions, action: :permissions, as: :permissions
            # Endpoint for getting the currently signed in user.
            get :current
          end
        end
      end
    end
  end
end
