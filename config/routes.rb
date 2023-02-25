Rails.application.routes.draw do
  get 'bases/index'

  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :bases

  resources :users do
    collection do
      get 'search'
      get 'attendance_at_work_employees'
      post 'csv_import' # csvインポート用アクションを追加。
    end
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month' # この行が追加対象です。
    end
    resources :attendances, only: [:update] do
      member do
        get 'edit_overwork_request' # 残業申請モーダルを表示
        patch 'send_overwork_request' # 残業申請モーダル内容を送信
        get 'show_overwork_notice' # 送信された残業申請モーダル通知を表示
        patch 'update_overwork_notice' # 送信された残業申請モーダル通知の承認結果を反映
      end
    end
  end
end
