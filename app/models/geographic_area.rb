class GeographicArea < ActiveRecord::Base

  # acts_as_nested_set

  # internal references

  belongs_to :parent, class_name: "GeographicArea", foreign_key: :parent_id
  belongs_to :tdwg_parent, class_name: "GeographicArea", foreign_key: :tdwg_parent_id
  belongs_to :level0, class_name: "GeographicArea", foreign_key: :level0_id
  belongs_to :level1, class_name: "GeographicArea", foreign_key: :level1_id
  belongs_to :level2, class_name: "GeographicArea", foreign_key: :level2_id
  belongs_to :gadm_geo_item, class_name: "GeographicArea", foreign_key: :level2_id
  belongs_to :tdwg_geo_item, class_name: "GeographicArea", foreign_key: :tdwg_geo_item_id
  belongs_to :ne_geo_item, class_name: "GeographicArea", foreign_key: :ne_geo_item_id

  # external references

  belongs_to :geographic_item
  belongs_to :geographic_area_type

  # validations

  validates_associated :geographic_area_type
  validates :name, presence: true
  validates :data_origin, presence: true
  validate :earth_exception

  def earth_exception
    if name != 'Earth'
      if level0.nil?
        errors.add(:level0, "must be set to a GeographicArea.")
      end
      if parent.nil?
        errors.add(:parent, "must be set to a GeoreaphicArea.")
      end
    end
  end
end
