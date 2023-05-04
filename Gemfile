source 'https://rubygems.org'
ruby '2.7.7'
gem 'rails',        '~> 5.1.6'
gem 'rails-i18n' # 日本語化用gemを導入。
gem 'bcrypt'
gem 'faker' # サンプルユーザー生成用gemを導入。
gem 'bootstrap-sass'
gem 'will_paginate' # ページネーション生成用gemを導入。
gem 'bootstrap-will_paginate' # ページネーション見栄え向上用gemを導入。
gem 'puma',         '~> 3.7'
gem 'sass-rails',   '~> 5.0'
gem 'uglifier',     '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks',   '~> 5'
gem 'jbuilder',     '~> 2.5'
gem 'ransack' # 検索フォーム用gemを導入。
gem 'rounding' # 時間の指定単位区切り用gemを導入。
gem 'roo' # CSVインポート用gemを導入。
gem 'coffee-script-source', '1.8.0'

group :development, :test do
  gem 'sqlite3'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows環境ではtzinfo-dataというgemを含める必要があります
# Mac環境でもこのままでOKです
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
