module PgSearch
  module Features
    class TSearch < Feature
      module TSHeadline
        def build_sql(document, tsquery, options)
          "ts_headline((#{document}), (#{tsquery}), '#{format_options(options)}')"
        end
        module_function :build_sql

        private

        def format_options(options)
          return nil unless options.is_a?(Hash)

          headline_options = {}
          headline_options["StartSel"] = options[:start_sel]
          headline_options["StopSel"] = options[:stop_sel]

          headline_options.map do |key, value|
            "#{key} = #{value}" if value
          end.compact.join(", ")
        end
        module_function :format_options
      end
    end
  end
end
