# rubocop:disable Metrics/ClassLength

require "pg_search/compatibility"
require "pg_search/features/tsearch/ts_queryable"
require "pg_search/features/tsearch/ts_documentable"
require "pg_search/features/tsearch/tsearch_rank"
require "pg_search/features/tsearch/ts_headline"
require "active_support/core_ext/module/delegation"

module PgSearch
  module Features
    class TSearch < Feature
      include TSQueryable
      include TSDocumentable

      def initialize(*args)
        super

        pg_version = model.connection.send(:postgresql_version)

        if options[:prefix] && pg_version < 80400
          raise PgSearch::NotSupportedForPostgresqlVersion.new(<<-MESSAGE.strip_heredoc)
            Sorry, {:using => {:tsearch => {:prefix => true}}} only works in PostgreSQL 8.4 and above.")
          MESSAGE
        end

        if options[:highlight] && pg_version < 90000
          raise PgSearch::NotSupportedForPostgresqlVersion.new(<<-MESSAGE.strip_heredoc)
            Sorry, {:using => {:tsearch => {:highlight => true}}} only works in PostgreSQL 9.0 and above.")
          MESSAGE
        end
      end

      def conditions
        Arel::Nodes::Grouping.new(
          Arel::Nodes::InfixOperation.new("@@", arel_wrap(tsdocument), arel_wrap(tsquery))
        )
      end

      def rank
        arel_wrap( TSearchRank.build_sql(tsdocument, tsquery, options[:normalization]) )
      end

      def highlight
        arel_wrap( TSHeadline.build_sql(document, tsquery, options[:highlight]) )
      end

      private

      def dictionary
        Compatibility.build_quoted(options[:dictionary] || :simple)
      end

      def arel_wrap(sql_string)
        Arel::Nodes::Grouping.new(Arel.sql(sql_string))
      end
    end
  end
end
