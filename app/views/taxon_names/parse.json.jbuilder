json.data do
  json.protonyms do
    TaxonWorks::Vendor::Biodiversity::RANK_MAP.each_key do |r|
      json.set! r do
        json.array! @result[:protonyms][r] do |t|
          json.partial! '/taxon_names/base_attributes', taxon_name: t
        end
      end
    end
  end

  json.set! :parse, @result[:parse]
  json.unambiguous @result[:unambiguous]
  json.existing_combination_id @result[:existing_combination_id]
end


json.other_matches do
  @result[:other_matches].keys.each do |k|
    json.set! k do
      json.array! @result[:other_matches][k] do |t|
        json.partial! '/taxon_names/base_attributes', taxon_name: t
      end
    end
  end
end
