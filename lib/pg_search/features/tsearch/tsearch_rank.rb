module PgSearch
  module Features
    class TSearch < Feature
      module TSearchRank
        extend self

        DEFAULT_NORMALIZATION = 0

        def build_sql(document, tsquery, normalization)
          # From http://www.postgresql.org/docs/8.3/static/textsearch-controls.html
          #   0 (the default) ignores the document length
          #   1 divides the rank by 1 + the logarithm of the document length
          #   2 divides the rank by the document length
          #   4 divides the rank by the mean harmonic distance between extents (this is implemented only by ts_rank_cd)
          #   8 divides the rank by the number of unique words in document
          #   16 divides the rank by 1 + the logarithm of the number of unique words in document
          #   32 divides the rank by itself + 1
          # The integer option controls several behaviors, so it is a bit mask: you can specify one or more behaviors
          normalization = normalization || DEFAULT_NORMALIZATION

          "ts_rank((#{document}), (#{tsquery}), #{normalization})"
        end
      end
    end
  end
end
