# SchemaComments  [![Build Status](https://secure.travis-ci.org/akm/schema_comments.png)](http://travis-ci.org/akm/schema_comments)

## Install

### With Bundler
add this line into Gemfile

```
gem "schema_comments"
```

And do bundle install

```
bundle install
```

Or install gem manually

```
$ gem install schema_comments
```


## Overview
schema_commentsプラグインを使うと、テーブルとカラムにコメントを記述することができます。

```
class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table "products", :comment => '商品' do |t|
      t.string   "product_type_cd", :comment => '種別コード'
      t.integer  "price", :comment => "価格"
      t.string   "name", :comment => "商品名"
      t.datetime "created_at", :comment => "登録日時"
      t.datetime "updated_at", :comment => "更新日時"
    end
  end

  def self.down
    drop_table "products"
  end
end
```

このようなマイグレーションを実行すると、db/schema.rb のコメントが設定されているテーブル、カラムには以下のように出力されます。

```
ActiveRecord::Schema.define(:version => 0) do
  create_table "products", :force => true, :comment => '商品' do |t|
    t.string   "product_type_cd", :comment => '種別コード'
    t.integer  "price", :comment => "価格"
    t.string   "name", :comment => "商品名"
    t.datetime "created_at", :comment => "登録日時"
    t.datetime "updated_at", :comment => "更新日時"
  end
end
```

コメントは以下のメソッドで使用することが可能です。

```
columns, create_table, drop_table, rename_table
remove_column, add_column, change_column, rename_column
```


## コメントはどこに保存されるのか

db/schema_comments.yml にYAML形式で保存されます。
あまり推奨しませんが、もしマイグレーションにコメントを記述するのを忘れてしまった場合、db/schema_comments.yml
を直接編集した後、rake db:schema:dumpやマイグレーションを実行すると、db/schema.rbのコメントに反映されます。


## I18nへの対応

`schema_comments:i18n:update`タスクを実行すると、i18n用のYAMLを更新できます。

```
rake schema_comments:i18n:update
```

環境変数`LOCALE`で対象のロケールを指定可能ですが、指定されていなければ`I18n.locale`から取得します。

これは `config/application.rb` で以下のように指定可能です。

```
   config.i18n.default_locale = :ja
```


また出力先のYAMLのPATHを指定したい場合、YAML_PATHで指定が可能です。

```
rake schema_comments:i18n:update LOCALE=ja YAML_PATH=/path/to/yaml
```


## MySQLのビュー
MySQLのビューを使用した場合、元々MySQLではSHOW TABLES でビューも表示してしまうため、
ビューはテーブルとしてSchemaDumperに認識され、development環境ではMySQLのビューとして作成されているのに、
test環境ではテーブルとして作成されてしまい、テストが正しく動かないことがあります。
これを避けるため、schema_commentsでは、db/schema.rbを出力する際、テーブルに関する記述の後に、CREATE VIEWを行う記述を追加します。


## License
Copyright (c) 2008 - 2016 Takeshi AKIMA, released under the Ruby License
