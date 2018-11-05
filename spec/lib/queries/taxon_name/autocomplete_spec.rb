require 'rails_helper'

describe Queries::TaxonName::Autocomplete, type: :model do

  let(:root) { FactoryBot.create(:root_taxon_name)}
  let(:genus) { Protonym.create(name: 'Erasmoneura', rank_class: Ranks.lookup(:iczn, 'genus'), parent: root) }
  let!(:species) { Protonym.create(name: 'vulnerata', rank_class: Ranks.lookup(:iczn, 'species'), parent: genus, verbatim_author: 'Fitch & Say', year_of_publication: 1800) }

  let(:name) { 'Erasmoneura vulnerata' }

  let(:query) { Queries::TaxonName::Autocomplete.new('') }

  specify '#autocomplete_cached_wildcard_whitespace open paren' do
    query.terms = 'Scaphoideus ('
    expect(query.autocomplete_cached_wildcard_whitespace.all).to be_truthy
  end

  specify '#autocomplete_name_author_year open paren' do
    query.terms = 'Scaphoideus ('
    expect(query.autocomplete_name_author_year.all).to be_truthy
  end

  specify '#open paren' do
    query.terms = 'Scaphoideus ('
    expect(query.autocomplete).to be_truthy
  end

  specify '#genus_species cf' do
    query.terms = 'Scaphoideus cf carinatus'
    expect(query.autocomplete).to be_truthy
  end

  specify '#autocomplete_top_name 1' do
    query.terms = 'vulnerata' 
    expect(query.autocomplete_top_name.first).to eq(species)
  end

  specify '#autocomplete_top_name 2' do
    query.terms = 'Erasmoneura' 
    expect(query.autocomplete_top_name.first).to eq(genus) 
  end

  specify '#autocomplete_top_cached' do
    query.terms = name 
    expect(query.autocomplete_top_cached.first).to eq(species)
  end

  specify '#autocomplete_cached_end_wildcard 3' do
    query.terms = 'Erasmon'
    expect(query.autocomplete_cached_end_wildcard.to_a).to contain_exactly(genus, species)
  end

  specify '#autocomplete_wildcard_joined_strings 1' do
    query.terms = 'vuln'
    expect(query.autocomplete_wildcard_joined_strings).to include(species)
  end

  specify '#autocomplete_wildcard_joined_strings 2' do
    query.terms = 'rasmon'
    expect(query.autocomplete_wildcard_joined_strings.first).to eq(genus)
  end

  specify '#autocomplete_wildcard_joined_strings 3' do
    query.terms = 'ulner'
    expect(query.autocomplete_wildcard_joined_strings.first).to eq(species)
  end

  specify '#autocomplete_wildcard_joined_strings 4' do
    query.terms = 'neur nerat'
    expect(query.autocomplete_wildcard_joined_strings).to include(species)
  end

  specify '#autocomplete_wildcard_joined_strings 5' do
    query.terms = 'E vul'
    expect(query.autocomplete_wildcard_joined_strings.first).to eq(species)
  end

  specify '#autocomplete_wildcard_joined_strings 6' do
    query.terms = 'E. vul'
    expect(query.autocomplete_wildcard_joined_strings.first).to eq(species)
  end

  specify '#autocomplete_wildcard_author_year_joined_pieces 1' do
    query.terms = 'Fitch'
    expect(query.autocomplete_wildcard_author_year_joined_pieces.first).to eq(species)
  end

  specify '#autocomplete_wildcard_author_year_joined_pieces 2' do
    query.terms = 'Say'
    expect(query.autocomplete_wildcard_author_year_joined_pieces.first).to eq(species)
  end

  specify '#autocomplete_wildcard_author_year_joined_pieces 3' do
    query.terms = '1800'
    expect(query.autocomplete_wildcard_author_year_joined_pieces.first).to eq(species)
  end

  specify '#autocomplete_wildcard_author_year_joined_pieces 4' do
    query.terms = 'Fitch 1800'
    expect(query.autocomplete_wildcard_author_year_joined_pieces.first).to eq(species)
  end



  # etc. ---

end
