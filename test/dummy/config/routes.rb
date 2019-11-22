Rails.application.routes.draw do

  # get 'news', to: 'contact#index'

  get 'news' => 'railspress/posts#index', as: :all_posts
  get 'news/:year' => 'railspress/posts#by_year', constraints: {year: /20[12]\d/}, as: :news_of_year
  get 'news/:year/:month' => 'railspress/posts#by_month', constraints: {year: /20[12]\d/, month: /(0?\d)|10|11|12/}
  get 'news/:slug' => 'railspress/posts#show'
  get 'news/show/:id' => 'railspress/posts#show_id', constraints: {id: /\d+/}
  get 'news/tag/:slug' => 'railspress/posts#tag'

  get 'test' => 'railspress/pages#test'

  get 'page/*slug' => 'railspress/pages#show', as: :show_page

#  mount Railspress::Engine => "/railspress"

  root 'railspress/pages#home'

end
