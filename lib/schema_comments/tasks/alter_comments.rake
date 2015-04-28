namespace :db do
  namespace :schema do
    namespace :comments do

      desc "update #{SchemaComments.yaml_path} from mysql comments of tables and columns"
      task :dump => :environment do
        conn = ActiveRecord::Base.connection
        db_table_comments = conn.select_all("SHOW TABLE STATUS").each_with_object({}){|row, d| d[row["Name"]] = row["Comment"]}
        db_table_comments.keys.each do |t|
          db_column_comments = conn.select_all("SHOW FULL COLUMNS FROM #{t}").each_with_object({}){|row, d| d[row["Field"]] = row["Comment"]}
        end
        root = {"table_comments" => db_table_comments, "column_comments" => db_column_comments}
        SchemaComments::SchemaComment::SortedStore.sort_yaml_content!(root)
        open(SchemaComments.yaml_path, "w"){|f| f.puts root.to_yaml }
      end

      desc "load #{SchemaComments.yaml_path} and alter table for mysql comments"
      task :load => :environment do
        conn = ActiveRecord::Base.connection
        creation = ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation.new(conn)

        db_tables = conn.tables
        db_table_comments = conn.select_all("SHOW TABLE STATUS").each_with_object({}){|row, d| d[row["Name"]] = row["Comment"]}
        root = YAML.load_file(SchemaComments.yaml_path)
        column_comments_root = root["column_comments"]
        root["table_comments"].each do |t, t_comment|
          unless db_tables.include?(t)
            $stderr.puts "\e[33mtable #{t.inspect} doesn't exist\e[0m"
            next
          end
          unless t_comment == db_table_comments[t]
            conn.execute("ALTER TABLE #{t} COMMENT '#{t_comment}'")
          end

          column_hash = conn.columns(t).each_with_object({}){|c, d| d[c.name] = c}
          db_column_comments = conn.select_all("SHOW FULL COLUMNS FROM #{t}").each_with_object({}){|row, d| d[row["Field"]] = row["Comment"]}
          column_comments = column_comments_root[t]
          column_comments.each do |c, c_comment|
            unless c_comment == db_column_comments[t]
              if col = column_hash[c]
                opts = col.sql_type.dup
                creation.send(:add_column_options!, opts, null: col.null, default: col.default, auto_increment: (col.extra == "auto_increment"))
                conn.execute("ALTER TABLE #{t} MODIFY #{c} #{opts} COMMENT '#{c_comment}'")
              end
            end
          end
        end
      end

    end
  end
end
