# This solution is based on the following:
# https://gist.github.com/drnic/9d6e63802f1a7517434c25bb80f2ec09
# https://gist.github.com/GlenCrawford/16163abab7852c1bd550547f29971c18

# In old legacy the modules (hacor, uma, meca etc.) had their own databases. In
# new legacy the engines (ivy, uma, meca etc.) used those same separate
# databases. This allowed the tables to not suffer from name clashes and also
# provided some isolation from the other modules/engines.
#
# With hindsight that isolation was not desirable.
#
# In ct-visualisation-app, the engines (ivy, uma, meca, etc.) use the same
# database but separate postgresql schemas.  This prevents the table name
# clashes whilst still allowing foreign keys to tables in different schemas.
#
# It may be the case that having them all in the same schema would be the
# better solution, but that seems a little too risky of a change at the moment.

# This file monkey patches active records' schema dumper to support multiple
# schemas.  This may stop working if active record is upgraded.  If you're
# reading this because it's stopped working, perhaps its time to reconsider
# having separate postgresql schemas.

require 'active_record/connection_adapters/postgresql_adapter'

class ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper
  # Overridden in order to call new method "schemas".
  def dump(stream)
    @options[:table_name_prefix] = "public."
    header(stream)
    extensions(stream)
    types(stream)
    schemas(stream)
    sequences(stream)
    tables(stream)
    trailer(stream)

    stream
  end

  private

  # Adds following lines just after the extensions:
  # * connection.execute "CREATE SCHEMA ..."
  # * connection.schema_search_path = ...
  def schemas(stream)
    @connection.schema_search_path.split(",").each do |name|
      stream.puts %(  connection.execute "CREATE SCHEMA IF NOT EXISTS #{name}")
    end
    stream.puts ""
    stream.puts %(  connection.schema_search_path = #{@connection.schema_search_path.inspect})
    stream.puts ""
  end

  # Overridden in order to build a list of tables with their schema prefix
  # (rest of the method is the same).
  def tables(stream)
    table_query = <<-SQL
          SELECT schemaname, tablename
          FROM pg_tables
          WHERE schemaname = ANY(current_schemas(false))
    SQL

    sorted_tables = @connection.exec_query(table_query, "SCHEMA").map do |table|
      "#{table["schemaname"]}.#{table["tablename"]}"
    end.sort

    sorted_tables.each do |table_name|
      table(table_name, stream) unless ignored?(table_name)
    end

    if @connection.supports_foreign_keys?
      sorted_tables.each do |tbl|
        foreign_keys(tbl, stream) unless ignored?(tbl)
      end
    end
  end

  def sequences(stream)
    sequence_query = <<-SQL
      SELECT sequence_schema, sequence_name, increment, start_value
      FROM information_schema.sequences 
      ORDER BY sequence_name 
    SQL

    sorted_seqs = @connection.exec_query(sequence_query, "SCHEMA")
      .sort_by { |seq| "#{seq["sequence_schema"]}.#{seq["sequence_name"]}" }

    out = StringIO.new
    sorted_seqs.each do |seq|
      out.print "  connection.execute \""
      out.print "CREATE SEQUENCE #{seq["sequence_schema"]}.#{seq["sequence_name"]}"
      out.print " START WITH #{seq["start_value"]}"
      out.print " INCREMENT BY #{seq["increment"]}"
      out.print " NO MINVALUE"
      out.print " NO MAXVALUE"
      out.print " CACHE 1"
      out.print "\""
      out.puts
    end
    out.puts

    out.rewind
    stream.puts out.read
  end
end
