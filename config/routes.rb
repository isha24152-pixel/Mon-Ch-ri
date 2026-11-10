Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  # ログイン状態に応じたルート分岐
  devise_scope :user do
    # ログイン済みの場合はチャット画面へ
    authenticated :user do
      root to: 'ai#chat', as: :authenticated_root
    end

    # 未ログインの場合はログイン画面へ
    unauthenticated do
      root to: 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  get 'ai', to: 'ai#chat'

  resources :nanas, except: [:index] do
    member do
      get :calendar
    end
  end
end