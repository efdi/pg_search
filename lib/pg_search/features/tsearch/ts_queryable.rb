module PgSearch
  module Features
    class TSearch < Feature
      module TSQueryable
        DISALLOWED_TSQUERY_CHARACTERS = /['?\\:]/

        def tsquery
          return "''" if query.blank?

          query_terms = query.split(" ").compact

          tsquery_terms(query_terms).join(options[:any_word] ? ' || ' : ' && ')
        end

        private

        def tsquery_terms(query_terms)
          query_terms.map do |term|
            unsanitized_term, negated = check_for_negation(term)
            sanitized_term = sanitize(unsanitized_term)

            terms = make_terms( term_sql(sanitized_term), negated )

            build_sql( tsquery_sql(terms) )
          end
        end

        def build_sql(tsquery_sql)
          Arel::Nodes::NamedFunction.new(
            "to_tsquery",
            [dictionary, tsquery_sql]
          ).to_sql
        end

        def tsquery_sql(terms)
          terms.inject do |memo, term|
            Arel::Nodes::InfixOperation.new("||", memo, Compatibility.build_quoted(term))
          end
        end

        def make_terms(term_sql, negated)
          # After this, the SQL expression evaluates to a string containing the term surrounded by single-quotes.
          # If :prefix is true, then the term will have :* appended to the end.
          # If negated is true, then the term will have ! prepended to the front.
          [
            (Compatibility.build_quoted('!') if negated),
            Compatibility.build_quoted("' "),
            term_sql,
            Compatibility.build_quoted(" '"),
            (Compatibility.build_quoted(":*") if options[:prefix])
          ].compact
        end

        def term_sql(term)
          Arel.sql(normalize(connection.quote(term)))
        end

        def check_for_negation(term)
          if options[:negation] && term.start_with?("!")
            term[0] = ''
            negated = true
          else
            negated = false
          end

          [term, negated]
        end

        def sanitize(term)
          term.gsub(DISALLOWED_TSQUERY_CHARACTERS, " ")
        end
      end
    end
  end
end
