module Queries

  # See
  #  http://www.slideshare.net/camerondutro/advanced-arel-when-activerecord-just-isnt-enough
  #  https://github.com/rails/arel
  #  http://robots.thoughtbot.com/using-arel-to-compose-sql-queries
  #  https://github.com/rails/arel/blob/master/lib/arel/predications.rb
  #  And this:
  #    http://blog.arkency.com/2013/12/rails4-preloading/
  #    User.includes(:addresses).where("addresses.country = ?", "Poland").references(:addresses)
  #

  # Lots of optimization possible, at minimum this is nice for nested OR
  class Otu::Autocomplete < Queries::Query

    # @return [Scope]
    def where_sql
      with_project_id.and(or_clauses).to_sql
    end

    # @return [Scope]
    def or_clauses
      clauses = [
        named,
        taxon_name_named,
        taxon_name_author_year_matches,
        with_id
      ].compact

      a = clauses.shift
      clauses.each do |b|
        a = a.or(b)
      end
      a
    end

    # @return [Scope]
    def all
      # For references, this is equivalent: Otu.eager_load(:taxon_name).where(where_sql)
      ::Otu.includes(:taxon_name).where(where_sql).references(:taxon_names).order(name: :asc).limit(50).order('taxon_names.cached ASC')
    end

    # @return [Arel::Table]
    def taxon_name_table
      ::TaxonName.arel_table
    end

    # @return [Arel::Table]
    def table
      ::Otu.arel_table
    end

    # @return [Arel::Nodes::Matches]
    def taxon_name_named
      taxon_name_table[:cached].matches_any(terms)
    end

    # @return [Arel::Nodes::Matches]
    def taxon_name_author_year_matches
      a = authorship
      return nil if a.nil?
      taxon_name_table[:cached_author_year].matches(a)
    end

    # @return [String]
    def authorship
      parser = ScientificNameParser.new
      a = parser.parse(query_string)
      b = a[:scientificName]
      return nil if b.nil? or b[:details].nil?

      b[:details].each do |detail|
        detail.each_value do |v|
          if v.kind_of?(Hash) && v[:authorship]
            return v[:authorship]
          end
        end
      end
      nil
    end

  end
end
