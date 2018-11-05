json.extract! taxon_name, :id, :name, :parent_id, :cached_html, :feminine_name, :masculine_name,
              :neuter_name, :cached_author_year, :etymology, :year_of_publication, :verbatim_author, :rank, :rank_string,
              :type, :created_by_id, :updated_by_id, :project_id, :cached_valid_taxon_name_id, :cached_original_combination, :cached_original_combination_html,
              :cached_secondary_homonym, :cached_primary_homonym, :created_at, :updated_at, :nomenclatural_code, :verbatim_name

json.partial! '/shared/data/all/metadata', object: taxon_name, klass: 'TaxonName'

# TODO, likely rename
json.name_string taxon_name_name_string(taxon_name)
json.original_combination full_original_taxon_name_tag(taxon_name) # contains HTML
