module SchemaComments
  module DummyMigration
    def rename_column(table, old_col, new_col, options = {})
      super(table, old_col, new_col)
    end
  end
end
