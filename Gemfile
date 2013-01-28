source "http://rubygems.org"

group :test do
  gem "sqlite3", :platform => :ruby
  gem "mysql"  , (RUBY_VERSION == '1.9.2' ? "~> 2.8.1" : ">= 0"), :platform => :ruby
  gem "mysql2" , :platform => :ruby

  # gem "activerecord-jdbcsqlite3-adapter", :platform => :jruby
  # gem "activerecord-jdbcmysql-adapter"  , :platform => :jruby
end

gemspec
