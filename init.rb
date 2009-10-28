unless ENV['SCHEMA_COMMENTS_DISABLED']
  require 'schema_comments'
  SchemaComments.setup
end
