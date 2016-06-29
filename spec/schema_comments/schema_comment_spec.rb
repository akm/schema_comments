# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), '../spec_helper')

describe SchemaComments::SchemaComment do
  let(:migration_path){ File.expand_path('../../migrations', __FILE__) }
  let(:ignored_tables){ %w(schema_migrations) }
  
  before(:each) do
    SchemaComments.yaml_path = File.expand_path(File.join(File.dirname(__FILE__), 'schema_comments.yml'))
    FileUtils.rm(SchemaComments.yaml_path) if File.exist?(SchemaComments.yaml_path)

    (ActiveRecord::Base.connection.tables - ignored_tables).each do |t|
      ActiveRecord::Base.connection.drop_table(t) rescue nil
    end
    ActiveRecord::Base.connection.initialize_schema_migrations_table
    ActiveRecord::Base.connection.execute "DELETE FROM #{ActiveRecord::Migrator.schema_migrations_table_name}"
  end

  describe :yaml_access do
    before{@original_yaml_path = SchemaComments.yaml_path}
    after {SchemaComments.yaml_path = @original_yaml_path}

    # http://d.hatena.ne.jp/akm/20091213#c1271134505
    # プラグインの更新ご苦労さまです。
    # とても便利に使わせていただいてます。
    #
    # ところが本日更新してみたら0.1.3になっていて、
    # コメントの生成に失敗するようになってしまいました。
    #
    # 原因を探ってみましたところ、
    # コメントを一個も書いていないマイグレーションでは、
    # nilにHashKeyOrderableをextendしようとして落ちていました。
    #
    # プラグインによって自動で作られるマイグレーションがあるのですが、
    # 必ずしもコメントを書くとは限らないので、
    # コメントがないときは無視？もしくはそのままカラム名をいれるのがいいのかなと思いました。
    #
    # # schema_comment.rb:154-164　あたり
    #
    # よろしければ対応していただけたらと思います。
    it "dump without column comment" do
      Dir.glob('*.rb').each{|file| require(file) if /^\d+?_.*/ =~ file}

      SwapOutput.stdout{ ActiveRecord::Migrator.up(migration_path, 8) }
      expect(ActiveRecord::Migrator.current_version).to eq 8

      tmp_dir = File.expand_path("../../tmp", __FILE__)
      FileUtils.mkdir_p(tmp_dir)
      db_path = File.join(tmp_dir, "schema_comments_users_without_column_hash.yml")
      src_path = File.expand_path("../schema_comments_users_without_column_hash.yml", __FILE__)
      FileUtils.cp(src_path, db_path)

      SchemaComments.yaml_path = db_path
      SchemaComments::SchemaComment.yaml_access do |db|
        expect(db['column_comments']['products']['name']).to eq "商品名"
        db['column_comments']['products']['name'] = "商品名"
      end
    end

    {
      "table_comments" => lambda{|db| db['column_comments']['users']['login'] = "ログイン"},
      "column_comments" => lambda{|db| db['table_comments']['users'] = "物品"},
      "column_hash" => lambda{|db| db['column_comments']['users']['login'] = "ログイン"}
    }.each  do |broken_type, proc|
      it "raise SchemaComments::YamlError with broken #{broken_type}" do
        Dir.glob('*.rb').each{|file| require(file) if /^\d+?_.*/ =~ file}

        SwapOutput.stdout{ ActiveRecord::Migrator.up(migration_path, 8) }
        expect(ActiveRecord::Migrator.current_version).to eq 8

        SchemaComments.yaml_path =
          File.expand_path(File.join(
            File.dirname(__FILE__), "schema_comments_broken_#{broken_type}.yml"))
        expect{
          SchemaComments::SchemaComment.yaml_access(&proc)
        }.to raise_error(SchemaComments::YamlError)
      end
    end

  end

end
