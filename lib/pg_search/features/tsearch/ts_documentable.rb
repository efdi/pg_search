module PgSearch
  module Features
    class TSearch < Feature
      module TSDocumentable
        def tsdocument
          tsdocument_terms = (columns_to_use || []).map do |search_column|
            column_to_tsvector(search_column)
          end

          if options[:tsvector_column]
            tsvector_columns = Array.wrap(options[:tsvector_column])

            tsdocument_terms << tsvector_columns.map do |tsvector_column|
              column_name = connection.quote_column_name(tsvector_column)

              "#{quoted_table_name}.#{column_name}"
            end
          end

          tsdocument_terms.join(' || ')
        end

        def columns_to_use
          if options[:tsvector_column]
            columns.select { |c| c.is_a?(PgSearch::Configuration::ForeignColumn) }
          else
            columns
          end
        end

        def column_to_tsvector(search_column)
          tsvector = Arel::Nodes::NamedFunction.new(
            "to_tsvector",
            [dictionary, Arel.sql(normalize(search_column.to_sql))]
          ).to_sql

          if search_column.weight.nil?
            tsvector
          else
            "setweight(#{tsvector}, #{connection.quote(search_column.weight)})"
          end
        end
      end
    end
  end
end
