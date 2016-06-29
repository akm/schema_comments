# -*- coding: utf-8 -*-
require 'spec_helper'

describe ActiveRecord::Migrator do
  let(:migration_path){ File.expand_path('../migrations', __FILE__) }
  let(:ignored_tables){ %w(schema_migrations) }

  before(:each) do
    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))
    FileUtils.rm(SchemaComments.yaml_path, :verbose => true) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - ignored_tables).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end

  it "test_valid_migration" do
    expect(ActiveRecord::Base.connection.tables - %w(schema_migrations)).to eq []

    Dir.glob('*.rb').each do |file|
      require(file) if /^\d+?_.*/ =~ file
    end

    ActiveRecord::Migrator.up(migration_path, 1)

    expect(ActiveRecord::Migrator.current_version).to eq 1
    expect(SchemaComments.table_comment('products')).to eq '商品'
    products_columns = {
      'id' => '商品',
      'product_type_cd' => '種別コード',
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }
    expect(SchemaComments.column_comments('products')).to eq products_columns

    ActiveRecord::Migrator.down(migration_path, 0)
    # expect(SchemaComments::SchemaComment.count).to eq 0

    ActiveRecord::Migrator.up(migration_path, 1)
    ActiveRecord::Migrator.up(migration_path, 2)
    expect(ActiveRecord::Migrator.current_version).to eq 2

    SchemaComments.clear_cache
    expect(SchemaComments.table_comment('product_names')).to eq '商品'
    products_columns = {
      'id' => '商品',
      'product_type_cd' => '種別コード',
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }
    expect(SchemaComments.column_comments('product_names')).to eq products_columns

    ActiveRecord::Migrator.down(migration_path, 1)
    expect(ActiveRecord::Migrator.current_version).to eq 1

    SchemaComments.clear_cache
    expect(SchemaComments.table_comment('products')).to eq '商品'
    products_columns = {
      'id' => '商品',
      'product_type_cd' => '種別コード',
      "price" => "価格",
      "name" => "商品名",
      "created_at" => "登録日時",
      "updated_at" => "更新日時"
    }
    expect(SchemaComments.column_comments('products')).to eq products_columns

    ActiveRecord::Migrator.up(migration_path, 4)
    expect(ActiveRecord::Migrator.current_version).to eq 4
    SchemaComments.clear_cache
    expect(SchemaComments.column_comment('products', 'name')).to eq '商品名'
    expect(SchemaComments.column_comment('products', 'price')).to be_nil
    # expect(SchemaComments::SchemaComment.count).to eq 5

    ActiveRecord::Migrator.down(migration_path, 3)
    expect(ActiveRecord::Migrator.current_version).to eq 3
    # expect(SchemaComments::SchemaComment.count).to eq 6

    ActiveRecord::Migrator.up(migration_path, 5)
    expect(ActiveRecord::Migrator.current_version).to eq 5
    SchemaComments.clear_cache
    expect(SchemaComments.column_comment('products', 'name')).to eq '商品名'

    ActiveRecord::Migrator.up(migration_path, 6)
    expect(ActiveRecord::Migrator.current_version).to eq 6
    SchemaComments.clear_cache
    expect(SchemaComments.column_comment('products', 'name')).to eq '名称'

    # Bug report from Ishikawa, Thanks!
    # schema_commentsのcolumn_commentsがうまく動かないみたいです。
    # カラムを定義するついでにコメントを付加するのは動くのですが、
    # コメントだけあとから付けようとすると、カラムへのコメントが付きません。
    #
    # column_comments(:table_name => {:column_name => "name"})
    # 上記のようにメソッドを呼び出しても、なぜか引数がHashではなくStringで取れてしまうみたいです。
    ActiveRecord::Migrator.up(migration_path, 7)
    expect(ActiveRecord::Migrator.current_version).to eq 7
    SchemaComments.clear_cache
    expect(SchemaComments.column_comment('products', 'name')).to eq '商品名称'
    expect(SchemaComments.column_comment('products', 'product_type_cd')).to eq 'カテゴリコード'

    ActiveRecord::Migrator.up(migration_path, 8)
    expect(ActiveRecord::Migrator.current_version).to eq 8

    ActiveRecord::Migrator.up(migration_path, 9)
    expect(ActiveRecord::Migrator.current_version).to eq 9
    SchemaComments.clear_cache
    expect(SchemaComments.column_comment('products', 'category_cd')).to eq 'カテゴリーコード'
  end

end
