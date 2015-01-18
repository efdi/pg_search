module PgSearch
  module Features
    class TSearch < Feature
      module TSQueryable
        DISALLOWED_TSQUERY_CHARACTERS = /['?\\:]/

        def tsquery
          return "''" if query.blank?
          query_terms = query.split(" ").compact
          tsquery_terms = query_terms.map { |term| tsquery_for_term(term) }
          tsquery_terms.join(options[:any_word] ? ' || ' : ' && ')
        end

        def tsquery_for_term(unsanitized_term)
          if options[:negation] && unsanitized_term.start_with?("!")
            unsanitized_term[0] = ''
            negated = true
          end

          sanitized_term = unsanitized_term.gsub(DISALLOWED_TSQUERY_CHARACTERS, " ")

          term_sql = Arel.sql(normalize(connection.quote(sanitized_term)))

          # After this, the SQL expression evaluates to a string containing the term surrounded by single-quotes.
          # If :prefix is true, then the term will have :* appended to the end.
          # If :negated is true, then the term will have ! prepended to the front.
          terms = [
            (Compatibility.build_quoted('!') if negated),
            Compatibility.build_quoted("' "),
            term_sql,
            Compatibility.build_quoted(" '"),
            (Compatibility.build_quoted(":*") if options[:prefix])
          ].compact

          tsquery_sql = terms.inject do |memo, term|
            Arel::Nodes::InfixOperation.new("||", memo, Compatibility.build_quoted(term))
          end

          Arel::Nodes::NamedFunction.new(
            "to_tsquery",
            [dictionary, tsquery_sql]
          ).to_sql
        end
      end
    end
  end
end
