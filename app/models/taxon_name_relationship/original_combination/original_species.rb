class TaxonNameRelationship::OriginalCombination::OriginalSpecies < TaxonNameRelationship::OriginalCombination

  # left_side
  def self.valid_subject_ranks
    NomenclaturalRank::ICZN::SpeciesGroup.descendants + NomenclaturalRank::ICN::Species + NomenclaturalRank::ICN::InfraspecificGroup.descendants
  end

  # right_side
  def self.valid_object_ranks
    NomenclaturalRank::ICZN::SpeciesGroup.descendants + NomenclaturalRank::ICN::Species + NomenclaturalRank::ICN::InfraspecificGroup.descendants
  end

  def self.assignment_method
    # aus.original_combination_form = bus
    :original_combination_species
  end

  def self.inverse_assignment_method
    # bus.set_as_species_in_original_combination(aus)
    :species_in_original_combination
  end

end
