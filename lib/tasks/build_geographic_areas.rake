# INIT tasks for RGeo, PostGIS, shape files (GADM and TDWG)

# TODO: Problems with GADM V2
#    28758: Not a valid geometry.
#   200655: Side location conflict at 33.489303588867358, 0.087361000478210826

SFG          = 'SpeciesFile Group'

# ISO Country Codes:
# See http://www.iso.org/iso/home/standards/country_codes.htm

ISO_3166_1_2 = 'ISO 3166-1-alpha-2' # ISO 3166-1:2006 two-letter country abbreviations
ISO_3166_1_3 = 'ISO 3166-1-alpha-3' # ISO 3166-1:2006 three-letter country abbreviations
# Other current choices are:
ISO_3166_3   = 'ISO 3166-3:1999' # Country names which have been deleted from -1 since 1974
ISO_3166_2   = 'ISO 3166-2:2007' # State or Province level for country codes in 3166-1

TDWG2_L1 = 'TDWG2 Level 1'
TDWG2_L2 = 'TDWG2 Level 2'
TDWG2_L3 = 'TDWG2 Level 3'
TDWG2_L4 = 'TDWG2 Level 4'

GADM2_0 = 'GADM2 Level 0'
GADM2_1 = 'GADM2 Level 1'
GADM2_2 = 'GADM2 Level 2'

NE0_10  = 'NaturalEarth-0 (10m)'
NE1_10  = 'NaturalEarth-1 (10m)'
NE_50  = 'NaturalEarth (50m)'
NE_110 = 'NaturalEarth (110m)'

EXTRA = 'Extra'

#
namespace :tw do
  namespace :init do

    desc 'Generate PostgreSQL/PostGIS records for shapefiles.'
    task :build_geographic_areas => [:environment] do

      class GARecord < GeographicArea
        @new_stuff = ''
        @attributes

        def attributes=(attributes)
          @attributes = attributes
        end

        def attributes
          @attributes
        end

        def new_stuff=(stuff)
          @new_stuff = stuff
        end

        def stuff
          @new_stuff
        end
      end

      place     = ENV['place']
      shapes    = ENV['shapes']

      # index is only expected to work for the GADM V2 shape file set: intended *only* as a
      # short-cut to a problem record.
      index     = ENV['index']

      # divisions is used to select only the processing of the division names in the GADM file.
      Divisions = false

      divisions = ENV['divisions']

      # build csv file list from 'place'

      # GenTable: set to true to generate the GeographicAreaType table here
      GenTable  = true
      # DoShape: set to true to include the reading of the shapes into the GeographicItem table;
      #          Otherwise, only the DBF files are used to populate the GeographicArea table
      DoShape   = false
      # BaseDir: where to find the tables to be used
      BaseDir   = '../shapes/'

      if place.nil?
        base_dir = BaseDir
      else
        base_dir = place.gsub('\\', '/')
      end

      if shapes.nil?
        do_shape = DoShape
      else
        do_shape = (shapes == 'true')
      end

      index = index.nil? ? 0 : index.to_i

      if divisions.nil?
        @divisions = Divisions
      else
        @divisions = true
      end

      if GenTable
        build_gat_table
        if do_shape
          # we use the entire shape file constellation
          Dir.glob(base_dir + '**/*.shp').each { |filename|
            read_shape(filename, index)
          }
        else
          # process all available files at the same time
          read_dbf(Dir.glob(base_dir + '**/*.dbf') + (Dir.glob(base_dir + '**/*.txt')))
        end
      end
    end
  end
end

def read_shape(filename, index)

  # TODO: For some reason, Georeference::FACTORY does not seem to be the default factory, so we are being specific here, to get the lenient polygon tests.  This gets us past the problem polygons, but does not actually deal with the problem.
  # See http://dazuma.github.io/rgeo-shapefile/rdoc/RGeo/Shapefile/Reader.html for reader options.

  # ne10 = RGeo::Shapefile::Reader.open('G:\Share\Downloads\PostgreSQL\PostGIS\10m_cultural\10m_cultural\ne_10m_admin_0_countries.shp', factory: Georeference::FACTORY)
  # gadm = RGeo::Shapefile::Reader.open('G:\Share\rails\shapes\gadm_v2_shp\gadm2.shp', factory: Georeference::FACTORY)

  RGeo::Shapefile::Reader.open(filename, factory: Georeference::FACTORY) { |file|

    file.seek_index(index)
    count = file.num_records
    ess   = (count == 1) ? '' : 's'
    puts "#{Time.now.strftime "%H:%M:%S"}: #{filename} contains #{count} item#{ess}."

    # things to do before each file

    case filename
      when /adm1/i
        # since we are going to have to skip XXX_adm0, we need to build a master records for North America,
        # the USA by hand
        mr = GeographicArea.where(name: 'United States')
        if mr[0].nil?
          mr = GeographicArea.new(name:                 'United States',
                                  country_id:           240,
                                  parent_id:            0,
                                  geographic_area_type: GeographicAreaType.where(name: 'Country')[0])
          mr.save
        end
      when /level1/i
        record = GeographicArea.where(name: 'Earth')
        if record.count == 0
          record    = GeographicArea.new(parent_id: nil,
                                         name:      'Earth')
          area_type = GeographicAreaType.where(name: 'Planet')[0]
          # save this record for later
          earth     = record.save
        else
          earth = record[0]
        end
      else
        # nothing to do
    end

    # record    = GeographicArea.new
    # area_type = GeographicAreaType.new

    time_then = Time.now
    file.each { |item|
      record = nil

      # todo: This processing is *very* specific, and currently only handles the USA_adm shape file case: it must be made to handle a more general case of GADM, and/or TDWG

      case filename
        when /USA_adm0/
          record    = GeorgaphicArea.new(parent_id:  0,
                                         name:       item[:NAME_ENGLISH],
                                         country_id: item[:PID])
          area_type = GeographicAreaType.where(name: 'Country')[0]
        #if area_type.nil?
        #  at = GeographicAreaType.new(name: 'Country')
        #  at.save
        #  area_type = at
        #end
        when /USA_adm1/
          record    = GeographicArea.new(parent_id:  item[:ID_0],
                                         name:       item[:NAME_1],
                                         state_id:   item[:ID_1],
                                         country_id: item[:ID_0])
          area_type = GeographicAreaType.where(name: item[:TYPE_1])
        #if area_type.nil?
        #  at = GeographicAreaType.new(name: item[:TYPE_1])
        #  at.save
        #  area_type = at
        #end
        when /USA_adm2/
          record    = GeographicArea.new(parent_id:  item[:ID_1],
                                         name:       item[:NAME_2],
                                         state_id:   item[:ID_1],
                                         country_id: item[:ID_0],
                                         county_id:  item[:ID_2])
          area_type = GeographicAreaType.where(name: item[:TYPE_2])
        #if area_type.nil?
        #  at = GeographicAreaType.new(name: item[:TYPE_2])
        #  at.save
        #  area_type = at
        #end
        when /GADM/i
        when /level1/
          record = GeographicArea.new(parent_id: earth.id,
                                      name:      item['LEVEL1_NAM'])
          GeographicAreaType.where(name: item[''])
        when /level2/
        when /level3/
        when /level4/
        else
      end
      if !(record.nil?)
        record.geographic_area_type          = area_type[0]
        record.geographic_item               = GeographicItem.new
        record.geographic_item.multi_polygon = item.geometry
        record.save

        case filename
          when /USA_adm0/
            # when country, find parent continent
            # parent_record = GeographicArea.where({parent_id: 0, country_id: 0})[0]
            parent_record = GeographicArea.new(name:                 'North America',
                                               geographic_area_type: GeographicAreaType.where(name: 'Continent')[0])
          when /USA_adm1/
            # when state, find parent country
            parent_record = GeographicArea.where({state_id: nil, country_id: record.country_id})[0]
          when /USA_adm2/
            # when county, find parent state
            parent_record = GeographicArea.where({state_id: record.parent_id})[0]
          else

        end
        count = record.geographic_item.multi_polygon.num_geometries
        ess   = (count == 1) ? '' : 's'
        puts "#{'% 5d' % (item.index + 1)}:  #{record.geographic_area_type.name} of #{record.name} in the #{parent_record.geographic_area_type.name} of #{parent_record.name} => #{count} polygon#{ess}."
      else
        # this processing is specifically for GADM2
        if item.geometry.nil?
          item_type = 'Bad geometry'
          count_geo = 0
        else
          item_type = item.geometry.geometry_type
          count_geo = item.geometry.num_geometries
        end
        ess = (count_geo == 1) ? 'y' : 'ies'

        snap      = Time.now
        elapsed   = snap - time_then
        time_then = snap
        case filename
          when /GADM/i

            i5 = item['NAME_5']
            s5 = i5.empty? ? '' : (i5 + ', ')
            i4 = item['NAME_4']
            s4 = i4.empty? ? '' : (i4 + ', ')
            i3 = item['NAME_3']
            s3 = i3.empty? ? '' : (i3 + ', ')
            i2 = item['NAME_2']
            s2 = i2.empty? ? '' : (i2 + ', ')
            i1 = item['NAME_1']
            s1 = i1.empty? ? '' : (i1 + ', ')
            puts item.attributes
            puts "#{Time.at(time_then).strftime "%T"}: #{Time.at(elapsed).getgm.strftime "%H:%M:%S"}: #{item_type}#{'% 5d' % (item.index + 1)} (of #{count} items)(#{count_geo} geometr#{ess}) is called \'#{s5}#{s4}#{s3}#{s2}#{s1}#{item['NAME_0']}\'."
          when /level1/
            puts "#{Time.at(time_then).strftime "%T"}: #{Time.at(elapsed).getgm.strftime "%H:%M:%S"}: #{item['LEVEL1_COD']}, #{item['LEVEL1_NAM']}:  #{item_type}, (#{count_geo} geometr#{ess})"
          when /level2/
            puts "#{Time.at(time_then).strftime "%T"}: #{Time.at(elapsed).getgm.strftime "%H:%M:%S"}: #{item['LEVEL2_COD']}, #{item['LEVEL2_NAM']}, #{item['LEVEL1_NAM']}:  #{item_type}, (#{count_geo} geometr#{ess})"
          when /level3/
            o1 = Time.at(time_then).strftime "%T"
            o2 = Time.at(elapsed).getgm.strftime "%H:%M:%S"
            o3 = item['LEVEL2_COD']
            o4 = item['LEVEL3_COD']
            o5 = item['LEVEL3_NAM']
            o6 = item_type
            o7 = count_geo
            o8 = ess
            puts "#{o1}: #{o2}: #{o3}#{o4}, #{o5}:  #{o6}, (#{o7} geometr#{o8})"
          when /level4/
            # "ISO_Code","Level_4_Na","Level4_cod","Level4_2","Level3_cod","Level2_cod","Level1_cod"
            o1 = Time.at(time_then).strftime "%T"
            o2 = Time.at(elapsed).getgm.strftime "%H:%M:%S"
            o3 = item['ISO_Code']
            o9 = item['Level2_cod']
            o4 = item['Level4_cod']
            o5 = item['Level_4_Na']
            o6 = item_type
            o7 = count_geo
            o8 = ess

            puts "#{o1}: #{o2}: #{o3}: #{o9}#{o4},  #{o5}:  #{o6}, (#{o7} geometr#{o8})"
          else
        end

      end
    }
  } if !(filename =~ /[0]/)

end

def read_dbf(filenames)

  # things to do before any file

  # make sure the earth record exists and is available

  divisions   = false
  dhaualagiri = 0

  earth = GeographicArea.where(name: 'Earth')
  if earth.count == 0
    # create the record
    earth                      = GeographicArea.new(parent_id:   nil,
                                                    level0:      nil,
                                                    data_origin: SFG,
                                                    name:        'Earth')
    earth.geographic_area_type = GeographicAreaType.where(name: 'Planet').first
    # save this record for later
    earth.save!
  else
    # use the (first) record we found
    earth = earth.first
  end

  ne0_10, ne0_50, ne0_110, ne1_10, ne1_50, ne1_110 = nil, nil, nil, nil, nil, nil, nil
  iso, lvl1, lvl2, lvl3, lvl4, gadm2               = nil, nil, nil, nil, nil, nil

  filenames.sort!

  filenames.each { |filename|

    puts filename
    #breakpoint.save
    raise if !File.exist?(filename)

    case filename
      when /ne_10m_admin_0_countries\.dbf/i
        ne0_10 = DBF::Table.new(filename)
      when /ne_50m_admin_0_countries\.dbf/i
        ne0_50 = nil # DBF::Table.new(filename)
      when /ne_110m_admin_0_countries\.dbf/i
        ne0_110 = nil # ne0_110 = DBF::Table.new(filename)
      when /ne_10m_admin_1_states_provinces_shp\.dbf/i
        ne1_10 = DBF::Table.new(filename)
      when /ne_50m_admin_1_states_provinces_shp\.dbf/i
        ne1_50 = nil # DBF::Table.new(filename)
      when /ne_110m_admin_1_states_provinces_shp\.dbf/i
        ne1_110 = nil # ne1_110 = DBF::Table.new(filename)
      when /level1/i
        lvl1 = DBF::Table.new(filename)
      when /level2/i
        lvl2 = DBF::Table.new(filename)
      when /level3/i
        lvl3 = DBF::Table.new(filename)
      when /level4/i
        lvl4 = DBF::Table.new(filename)
      when /country_names_and_code_elements/i
        iso = File.open(filename)
      when /gadm2/i
        gadm2 = DBF::Table.new(filename)
      else
    end
  }

  n10, n50, n110, ne_names, ne_ids, ne_a3, ne_a2, ne_adm0                      = {}, {}, {}, {}, {}, {}, {}, {}
  @lvl0_items, @lvl1_items, @lvl2_items, @lvl3_items, @lvl4_items, @lvl5_items = {}, {}, {}, {}, {}, {}

  # @global_keys will be filled such that ga.name is the key for easier location later
  @global_keys                                                                 = {}
  gat5                                                                         = GeographicAreaType.where(name: 'Country').first
  gat6                                                                         = GeographicAreaType.where(name: 'Area').first

  if ne0_110 != nil

    ne0_110_example = {"scalerank"  => 1,
                       "featurecla" => "Admin-0 country",
                       "labelrank"  => 3.0,
                       "sovereignt" => "Afghanistan",
                       "sov_a3"     => "AFG",
                       "adm0_dif"   => 0.0,
                       "level"      => 2.0,
                       "type"       => "Sovereign country",
                       "admin"      => "Afghanistan",
                       "adm0_a3"    => "AFG",
                       "geou_dif"   => 0.0,
                       "geounit"    => "Afghanistan",
                       "gu_a3"      => "AFG",
                       "su_dif"     => 0.0,
                       "subunit"    => "Afghanistan",
                       "su_a3"      => "AFG",
                       "brk_diff"   => 0.0,
                       "name"       => "Afghanistan",
                       "name_long"  => "Afghanistan",
                       "brk_a3"     => "AFG",
                       "brk_name"   => "Afghanistan",
                       "brk_group"  => "",
                       "abbrev"     => "Afg.",
                       "postal"     => "AF",
                       "formal_en"  => "Islamic State of Afghanistan",
                       "formal_fr"  => "",
                       "note_adm0"  => "",
                       "note_brk"   => "",
                       "name_sort"  => "Afghanistan",
                       "name_alt"   => "",
                       "mapcolor7"  => 5.0,
                       "mapcolor8"  => 6.0,
                       "mapcolor9"  => 8.0,
                       "mapcolor13" => 7.0,
                       "pop_est"    => 28400000.0,
                       "gdp_md_est" => 22270.0,
                       "pop_year"   => -99.0,
                       "lastcensus" => 1979.0,
                       "gdp_year"   => -99.0,
                       "economy"    => "7. Least developed region",
                       "income_grp" => "5. Low income",
                       "wikipedia"  => -99.0,
                       "fips_10"    => "",
                       "iso_a2"     => "AF",
                       "iso_a3"     => "AFG",
                       "iso_n3"     => "004",
                       "un_a3"      => "004",
                       "wb_a2"      => "AF",
                       "wb_a3"      => "AFG",
                       "woe_id"     => -99.0,
                       "adm0_a3_is" => "AFG",
                       "adm0_a3_us" => "AFG",
                       "adm0_a3_un" => -99.0,
                       "adm0_a3_wb" => -99.0,
                       "continent"  => "Asia",
                       "region_un"  => "Asia",
                       "subregion"  => "Southern Asia",
                       "region_wb"  => "South Asia",
                       "name_len"   => 11.0,
                       "long_len"   => 11.0,
                       "abbrev_len" => 4.0,
                       "tiny"       => -99.0,
                       "homepart"   => 1.0}

    ne0_110.each { |item|

      #set up future process
      ga           = nil
      add_record   = true
      p1           = nil

      # gather data from record
      nation_name  = item.name # two_tick(item.name.titlecase)
      nation_code3 = item.iso_a3
      nation_code2 = item.iso_a2
      adm0_a3      = item.adm0_a3
      ne110_id     = item.iso_n3
      area_type    = add_gat(item.type)

      # There are some reasons NOT to actually create a record:
      #   1.  The (apparent) index (iso_n3) is set to '-99'
      #   2.  The adm0_A3 code is apparently NOT an iso one.

      # we are using what appears to be the iso A3 code to qualify these records
      if nation_code3 =~ /\A[A-Z]{3}\z/
        if nation_code3 != adm0_a3
          p1 = " (#{adm0_a3}) "
        else
          p1 = ' '
        end
      else
        add_record = false
      end

      if ne110_id =~ /\A\d{3}\z/
      else
        add_record = false
      end

      # the only time we use the iso A2 code is if it matches the proper form;
      # otherwise, we just null it out
      if nation_code2 =~ /\A[A-Z]{2}\z/
      else
        nation_code2 = nil
      end

      if add_record
        # check to see if we have a nation by the current code in our list
        # this is unlikely, if we have not processed any of the 110m data
        if ne_a3[nation_code3].nil?
          # We will need to create new GeoArea records so that we can check for typing anomalies and
          # misplaced areas later, and so that we have the iso codes up to which to match during later processing.

          ga             = GeographicArea.new(parent:               earth,
                                              # if we create records here, they will specifically
                                              # *not* be TDWG records
                                              # or GADM records
                                              tdwg_parent:          nil,
                                              name:                 two_tick(nation_name),
                                              iso_3166_a3:          nation_code3,
                                              adm0_a3:              adm0_a3,
                                              data_origin:          NE_110,
                                              neID:                 ne110_id,
                                              geographic_area_type: area_type)

          ga.iso_3166_a2 = nation_code2 if ga.iso_3166_a2.nil?
          ga.level0      = ga

          puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{area_type.name} of #{nation_name}\t\tAdded. (110m)"

        else
          ga = ne_a3[nation_code3]
          if ga.neID != ne110_id
            add_record = add_record
          end
          # found a record with the right name
          puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{ga.geographic_area_type.name} of #{nation_name}\t\tMatched #{ga.geographic_area_type.name} of #{ga.name}."
          ga.geographic_area_type = area_type
          ga.neID                 = ne110_id
          ga.data_origin          = NE_110 if ga.data_origin.nil?
        end
        ne_a3.merge!(ga.iso_3166_a3 => ga)
        ne_names.merge!(ga.name => ga)
        ne_ids.merge!(ga.neID => ga)
        ne_a2.merge!(ga.iso_3166_a2 => ga) if ga.iso_3166_a2 =~ /\A[A-Z]{2}\z/
      end
    }
  end

  if ne1_110 != nil

    ne1_110_example = {"scalerank"  => 2,
                       "featurecla" => "Admin-1 scale rank",
                       "adm1_code"  => "USA-3514",
                       "diss_me"    => 3514,
                       "adm1_cod_1" => "USA-3514",
                       "iso_3166_2" => "US-MN",
                       "wikipedia"  => "http://en.wikipedia.org/wiki/Minnesota",
                       "sr_sov_a3"  => "US1",
                       "sr_adm0_a3" => "USA",
                       "iso_a2"     => "US",
                       "adm0_sr"    => 1,
                       "admin0_lab" => 2,
                       "name"       => "Minnesota",
                       "name_alt"   => "MN|Minn.",
                       "name_local" => "",
                       "type"       => "State",
                       "type_en"    => "State",
                       "code_local" => "US32",
                       "code_hasc"  => "US.MN",
                       "note"       => "",
                       "hasc_maybe" => "",
                       "region"     => "Midwest",
                       "region_cod" => "",
                       "region_big" => "West North Central",
                       "big_code"   => "",
                       "provnum_ne" => 0,
                       "gadm_level" => 1,
                       "check_me"   => 10,
                       "scaleran_1" => 2,
                       "datarank"   => 1,
                       "abbrev"     => "Minn.",
                       "postal"     => "MN",
                       "area_sqkm"  => 0.0,
                       "sameascity" => -99,
                       "labelrank"  => 0,
                       "featurec_1" => "Admin-1 scale rank",
                       "admin"      => "United States of America",
                       "name_len"   => 9,
                       "mapcolor9"  => 1,
                       "mapcolor13" => 1}

    ne1_110.each { |item|

      #set up future process
      ga         = nil
      add_record = true
      p1         = nil

      # gather data from record
      area_name  = item.name # two_tick(item.name.titlecase)
      area_code3 = item.iso_a3
      area_code2 = item.iso_a2
      adm0_a3    = item.adm0_a3
      ne110_id   = item.iso_n3
      area_type  = add_gat(item.type)

      # There are some reasons NOT to actually create a record:
      #   1.  The (apparent) index (iso_n3) is set to '-99'
      #   2.  The adm0_A3 code is apparently NOT an iso one.

      # we are using what appears to be the iso A3 code to qualify these records
      if nation_code3 =~ /\A[A-Z]{3}\z/
        if nation_code3 != adm0_a3
          p1 = " (#{adm0_a3}) "
        else
          p1 = ' '
        end
      else
        add_record = false
      end

      if ne110_id =~ /\A\d{3}\z/
      else
        add_record = false
      end

      # the only time we use the iso A2 code is if it matches the proper form;
      # otherwise, we just null it out
      if nation_code2 =~ /\A[A-Z]{2}\z/
      else
        nation_code2 = nil
      end

      if add_record
        # check to see if we have a nation by the current code in our list
        # this is unlikely, if we have not processed any of the 110m data
        if ne_a3[nation_code3].nil?
          # We will need to create new GeoArea records so that we can check for typing anomalies and
          # misplaced areas later, and so that we have the iso codes up to which to match during later processing.

          ga             = GeographicArea.new(parent:               earth,
                                              # if we create records here, they will specifically
                                              # *not* be TDWG records
                                              # or GADM records
                                              tdwg_parent:          nil,
                                              name:                 nation_name,
                                              iso_3166_a3:          nation_code3,
                                              adm0_a3:              adm0_a3,
                                              data_origin:          NE_110,
                                              neID:                 ne110_id,
                                              geographic_area_type: area_type)

          ga.iso_3166_a2 = nation_code2 if ga.iso_3166_a2.nil?
          ga.level0      = ga

          puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{area_type.name} of #{nation_name}\t\tAdded. (110m)"

        else
          ga = ne_a3[nation_code3]
          if ga.neID != ne110_id
            add_record = add_record
          end
          # found a record with the right name
          puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{ga.geographic_area_type.name} of #{nation_name}\t\tMatched #{ga.geographic_area_type.name} of #{ga.name}."
          ga.geographic_area_type = area_type
          ga.neID                 = ne110_id
          ga.data_origin          = NE_110 if ga.data_origin.nil?
        end
        ne_a3.merge!(ga.iso_3166_a3 => ga)
        ne_names.merge!(ga.name => ga)
        ne_ids.merge!(ga.neID => ga)
        ne_a2.merge!(ga.iso_3166_a2 => ga) if ga.iso_3166_a2 =~ /\A[A-Z]{2}\z/
      end

    }
  end

  if ne0_50 != nil

    ne0_50_example = {'scalerank'  => 5,
                      'featurecla' => 'Admin-0 country',
                      'labelrank'  => 5.0,
                      'sovereignt' => 'Australia',
                      'sov_a3'     => 'AU1',
                      'adm0_dif'   => 1.0,
                      'level'      => 2.0,
                      'type'       => 'Dependency',
                      'admin'      => 'Ashmore and Cartier Islands',
                      'adm0_a3'    => 'ATC',
                      'geou_dif'   => 0.0,
                      'geounit'    => 'Ashmore and Cartier Islands',
                      'gu_a3'      => 'ATC',
                      'su_dif'     => 0.0,
                      'subunit'    => 'Ashmore and Cartier Islands',
                      'su_a3'      => 'ATC',
                      'brk_diff'   => 0.0,
                      'name'       => 'Ashmore and Cartier Is.',
                      'name_long'  => 'Ashmore and Cartier Islands',
                      'brk_a3'     => 'ATC',
                      'brk_name'   => 'Ashmore and Cartier Is.',
                      'brk_group'  => '',
                      'abbrev'     => 'A.C.Is.',
                      'postal'     => 'AU',
                      'formal_en'  => 'Territory of Ashmore and Cartier Islands',
                      'formal_fr'  => '',
                      'note_adm0'  => 'Auz.',
                      'note_brk'   => '',
                      'name_sort'  => 'Ashmore and Cartier Islands',
                      'name_alt'   => '',
                      'mapcolor7'  => 1.0,
                      'mapcolor8'  => 2.0,
                      'mapcolor9'  => 2.0,
                      'mapcolor13' => 7.0,
                      'pop_est'    => -99.0,
                      'gdp_md_est' => -99.0,
                      'pop_year'   => -99.0,
                      'lastcensus' => -99.0,
                      'gdp_year'   => -99.0,
                      'economy'    => '7. Least developed region',
                      'income_grp' => '5. Low income',
                      'wikipedia'  => -99.0,
                      'fips_10'    => '',
                      'iso_a2'     => '-99',
                      'iso_a3'     => '-99',
                      'iso_n3'     => '036',
                      'un_a3'      => '-099',
                      'wb_a2'      => '-99',
                      'wb_a3'      => '-99',
                      'woe_id'     => -99.0,
                      'adm0_a3_is' => 'AUS',
                      'adm0_a3_us' => 'ATC',
                      'adm0_a3_un' => -99.0,
                      'adm0_a3_wb' => -99.0,
                      'continent'  => 'Oceania',
                      'region_un'  => 'Oceania',
                      'subregion'  => 'Australia and New Zealand',
                      'region_wb'  => 'East Asia & Pacific',
                      'name_len'   => 23.0,
                      'long_len'   => 27.0,
                      'abbrev_len' => 7.0,
                      'tiny'       => -99.0,
                      'homepart'   => -99.0}

    ne0_50.each { |item|

      #set up future process
      ga           = nil
      add_record   = true
      p1           = nil

      # gather data from record
      nation_name  = item.name # two_tick(item.name.titlecase)
      nation_code3 = item.iso_a3
      nation_code2 = item.iso_a2
      adm0_a3      = item.adm0_a3
      ne50_id      = item.iso_n3
      area_type    = add_gat(item.type)

      # There are some reasons NOT to actually create a record:
      #   1.  The (apparent) index (iso_n3) is set to '-99'
      #   2.  The A3 code is apparently NOT an iso one.

      # we are using what appears to be the iso A3 code to qualify these records
      if nation_code3 =~ /\A[A-Z]{3}\z/
        if nation_code3 != adm0_a3
          p1 = " (#{adm0_a3}) "
        else
          p1 = ' '
        end
      else
        add_record = false
      end

      if ne50_id =~ /\A\d{3}\z/
      else
        add_record = false
      end

      # the only time we use the iso A2 code is if it matches the proper form;
      # otherwise, we just null it out
      if nation_code2 =~ /\A[A-Z]{2}\z/
      else
        nation_code2 = nil
      end

      if add_record
        # check to see if we have a nation by the current code in our list
        # this is unlikely, if we have not processed any of the 110m data
        if ne_a3[nation_code3].nil?
          # We will need to create new GeoArea records so that we can check for typing anomalies and
          # misplaced areas later, and so that we have the iso codes up to which to match during later processing.

          ga             = GeographicArea.new(parent:               earth,
                                              # if we create records here, they will specifically
                                              # *not* be TDWG records
                                              # or GADM records
                                              tdwg_parent:          nil,
                                              name:                 nation_name,
                                              iso_3166_a3:          nation_code3,
                                              adm0_a3:              adm0_a3,
                                              data_origin:          NE_50,
                                              neID:                 ne50_id,
                                              geographic_area_type: area_type)

          ga.iso_3166_a2 = nation_code2 if ga.iso_3166_a2.nil?
          ga.level0      = ga

          puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{area_type.name} of #{nation_name}\t\tAdded. (50m)"

        else
          ga = ne_a3[nation_code3]
          if ga.neID != ne50_id
            add_record = add_record
          end
          # found a record with the right name
          puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{ga.geographic_area_type.name} of #{nation_name}\t\tMatched #{ga.geographic_area_type.name} of #{ga.name}."
          ga.geographic_area_type = area_type
          ga.neID                 = ne50_id
          ga.data_origin          = NE_50 if ga.data_origin.nil?
        end
        ne_a3.merge!(ga.iso_3166_a3 => ga)
        ne_names.merge!(ga.name => ga)
        ne_ids.merge!(ga.neID => ga)
        ne_a2.merge!(ga.iso_3166_a2 => ga) if ga.iso_3166_a2 =~ /\A[A-Z]{2}\z/
      end
    }
  end

  if ne0_10 != nil

    ne0_10_example = {"scalerank"  => 3,
                      "featurecla" => "Admin-0 country",
                      "labelrank"  => 5.0,
                      "sovereignt" => "Netherlands",
                      "sov_a3"     => "NL1",
                      "adm0_dif"   => 1.0,
                      "level"      => 2.0,
                      "type"       => "Country",
                      "admin"      => "Aruba",
                      "adm0_a3"    => "ABW",
                      "geou_dif"   => 0.0,
                      "geounit"    => "Aruba",
                      "gu_a3"      => "ABW",
                      "su_dif"     => 0.0,
                      "subunit"    => "Aruba",
                      "su_a3"      => "ABW",
                      "brk_diff"   => 0.0,
                      "name"       => "Aruba",
                      "name_long"  => "Aruba",
                      "brk_a3"     => "ABW",
                      "brk_name"   => "Aruba",
                      "brk_group"  => "",
                      "abbrev"     => "Aruba",
                      "postal"     => "AW",
                      "formal_en"  => "Aruba",
                      "formal_fr"  => "",
                      "note_adm0"  => "Neth.",
                      "note_brk"   => "",
                      "name_sort"  => "Aruba",
                      "name_alt"   => "",
                      "mapcolor7"  => 4.0,
                      "mapcolor8"  => 2.0,
                      "mapcolor9"  => 2.0,
                      "mapcolor13" => 9.0,
                      "pop_est"    => 103065.0,
                      "gdp_md_est" => 2258.0,
                      "pop_year"   => -99.0,
                      "lastcensus" => 2010.0,
                      "gdp_year"   => -99.0,
                      "economy"    => "6. Developing region",
                      "income_grp" => "2. High income: nonOECD",
                      "wikipedia"  => -99.0,
                      "fips_10"    => "",
                      "iso_a2"     => "AW",
                      "iso_a3"     => "ABW",
                      "iso_n3"     => "533",
                      "un_a3"      => "533",
                      "wb_a2"      => "AW",
                      "wb_a3"      => "ABW",
                      "woe_id"     => -99.0,
                      "adm0_a3_is" => "ABW",
                      "adm0_a3_us" => "ABW",
                      "adm0_a3_un" => -99.0,
                      "adm0_a3_wb" => -99.0,
                      "continent"  => "North America",
                      "region_un"  => "Americas",
                      "subregion"  => "Caribbean",
                      "region_wb"  => "Latin America & Caribbean",
                      "name_len"   => 5.0,
                      "long_len"   => 5.0,
                      "abbrev_len" => 5.0,
                      "tiny"       => 4.0,
                      "homepart"   => -99.0}

    ne0_10.each { |item|

      #set up future process
      ga           = nil
      add_record   = true
      add_adm0_a3  = false
      p1           = nil

      # gather data from record
      nation_name  = item.name # two_tick(item.name.titlecase)
      nation_code3 = item.iso_a3
      nation_code2 = item.iso_a2
      adm0_a3      = item.adm0_a3
      ne10_id      = item.iso_n3
      area_type    = add_gat(item.type)

      # There are some reasons NOT to actually create a record:
      #   1.  The (apparent) index (iso_n3) is set to '-99'
      #   2.  The A3 code is apparently NOT an iso one.

      # we are using what appears to be the iso A3 code to qualify these records
      if nation_code3 =~ /\A[A-Z]{3}\z/
        if nation_code3 != adm0_a3
          p1          = " (#{adm0_a3}) "
          add_adm0_a3 = true
        else
          p1 = ' '
        end
      else
        add_record = false
      end

      if ne10_id =~ /\A\d{3}\z/
      else
        add_record = false
      end

      # the only time we use the iso A2 code is if it matches the proper form;
      # otherwise, we just null it out
      if nation_code2 =~ /\A[A-Z]{2}\z/
      else
        nation_code2 = nil
      end

      if add_record
        names_key = {'l0' => nation_name}
        # check to see if we have a nation by the current name in our list
        # this is unlikely, if we have not processed any of the 110m data
        if ne_names[names_key].nil?
          # We will need to create new GeoArea records so that we can check for typing anomalies and
          # misplaced areas later, and so that we have the iso codes up to which to match during later processing.

          ga             = GeographicArea.new(parent:               earth,
                                              # if we create records here, they will specifically
                                              # *not* be TDWG records
                                              # or GADM records
                                              tdwg_parent:          nil,
                                              name:                 nation_name,
                                              iso_3166_a3:          nation_code3,
                                              adm0_a3:              adm0_a3,
                                              data_origin:          NE0_10,
                                              neID:                 ne10_id,
                                              geographic_area_type: area_type)

          ga.iso_3166_a2 = nation_code2 if ga.iso_3166_a2.nil?
          ga.level0      = ga

          # puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{area_type.name} of #{nation_name}\t\tAdded. (10m)"
          puts "'#{nation_code3}' (10m)"

        else
          ga = ne_a3[nation_code3]
          if ga.neID != ne10_id
            add_record = add_record
          end
          # found a record with the right name
          # puts "'#{nation_code3}'(#{ga.neID})#{p1}for #{ga.geographic_area_type.name} of #{nation_name}\t\tMatched #{ga.geographic_area_type.name} of #{ga.name}."
          ga.geographic_area_type = area_type
          ga.neID                 = ne10_id
          ga.data_origin          = NE0_10 if ga.data_origin.nil?
        end
        ne_a3.merge!(ga.iso_3166_a3 => ga)
        ne_names.merge!(names_key => ga)
        ne_ids.merge!(ga.neID => ga)
        ne_a2.merge!(ga.iso_3166_a2 => ga) if ga.iso_3166_a2 =~ /\A[A-Z]{2}\z/
        ne_adm0.merge!(ga.adm0_a3 => ga) if add_adm0_a3
      end
    }
  end

  if ne1_10 != nil

    ne1_10_example = {'adm1_code'  => 'AFG-1741',
                      'Shape_Leng' => 7.02734744327,
                      'Shape_Area' => 2.03728494123,
                      'diss_me'    => 1741,
                      'adm1_code_' => 'AFG-1741',
                      'iso_3166_2' => 'AF-',
                      'wikipedia'  => '',
                      'sr_sov_a3'  => 'AFG',
                      'sr_adm0_a3' => 'AFG',
                      'iso_a2'     => 'AF',
                      'adm0_sr'    => 1,
                      'admin0_lab' => 2,
                      'name'       => 'Badghis',
                      'name_alt'   => 'Badghes|Badghisat|Badgis',
                      'name_local' => '',
                      'type'       => 'Velayat',
                      'type_en'    => 'Province',
                      'code_local' => '',
                      'code_hasc'  => 'AF.BG',
                      'note'       => '',
                      'hasc_maybe' => '',
                      'region'     => '',
                      'region_cod' => '',
                      'region_big' => '',
                      'big_code'   => '',
                      'provnum_ne' => 7,
                      'gadm_level' => 1,
                      'check_me'   => 0,
                      'scalerank'  => 5,
                      'datarank'   => 5,
                      'abbrev'     => '',
                      'postal'     => 'BG',
                      'area_sqkm'  => 0.0,
                      'sameascity' => -99,
                      'labelrank'  => 5,
                      'featurecla' => 'Admin-1 scale rank',
                      'admin'      => 'Afghanistan',
                      'name_len'   => 7,
                      'mapcolor9'  => 8,
                      'mapcolor13' => 7}

    index = 0
    ne1_10.each { |item|

      index      += 1
      # puts item.attributes

      #set up future process
      ga         = nil
      add_record = true
      p1         = ' '

      # gather data from record
      area_name  = item.name # two_tick(item.name.titlecase)
      area_code2 = item.iso_a2
      adm0_a3    = item.sr_adm0_a3
      ne10_id    = item.adm1_code
      area_type  = add_gat(item.type_en)
      adm0_name  = item.name # two_tick(item.admin.titlecase)

      # There are some reasons NOT to actually create a record:
      #   1.  The (apparent) index (iso_n3) is set to '-99'
      #   2.  The A3 code is apparently NOT an iso one.

      if ne10_id =~ /\A[A-Z]{3}-\d{1,5}\z/
      else
        # puts "Reformed ne10_id: '#{ne10_id}' '#{item.name}' - #{adm0_a3} - #{item.admin}"
        ne10_id.gsub!('+', '-')
        ne10_id.gsub!('?', '')

        # add_record = false
      end

      # the only time we use the iso A2 code is if it matches the proper form;
      # otherwise, we just null it out
      if area_code2 =~ /\A[A-Z]{2}\z/
      else
        area_code2 = nil
      end

      if add_record
        names_key = {'l0' => adm0_name,
                     'l1' => area_name}

        # there is no reasonable thing to do, if the name is blank, so we bail.
        next if area_name.empty?

        # check to see if we have a nation by the current name in our list
        ga = ne_names[names_key]
        if ga.nil?
          # We will need to create new GeoArea records so that we can check for typing anomalies and
          # misplaced areas later, and so that we have the iso codes up to which to match during later processing.

          # find the parent country through the adm0_a3

          adm0_ga = ne_a3[adm0_a3]
          if adm0_ga.nil?
            puts "Using adm0_a3: '#{adm0_a3}' #{area_type.name} of #{area_name} of #{adm0_name}"
            # look for it in the adm0 stack
            adm0_ga = ne_adm0[adm0_a3]
            if adm0_ga.nil?
              # add a record for this adm0_a3 to act as parent
              adm0_ga        = GeographicArea.new(parent:               earth,
                                                  name:                 adm0_name,
                                                  adm0_a3:              adm0_a3,
                                                  iso_3166_a2:          area_code2,
                                                  data_origin:          NE1_10,
                                                  neID:                 ne10_id,
                                                  geographic_area_type: gat6)
              adm0_ga.level0 = adm0_ga

              puts "#{index}:\t\t'#{ne10_id}'#{p1}for #{gat6.name} of #{adm0_name} of #{adm0_ga.parent.name}\t\tAdded. (10m)"

              ne_adm0.merge!(adm0_a3 => adm0_ga)
              ne_a2.merge!(area_code2 => adm0_ga) if !area_code2.nil?

            else
              # already set
            end
          else
            # already set
          end

          ga        = GeographicArea.new(parent:               adm0_ga,
                                         # if we create records here, they will specifically
                                         # *not* be TDWG records
                                         # or GADM records
                                         tdwg_parent:          nil,
                                         name:                 area_name,
                                         adm0_a3:              nil,
                                         data_origin:          NE1_10,
                                         neID:                 ne10_id,
                                         geographic_area_type: area_type)
          ga.level0 = adm0_ga
          ga.level1 = ga

          puts "#{index}:\t\t'#{ne10_id}'#{p1}for #{area_type.name} of #{area_name} of #{ga.parent.name}\t\tAdded. (10m)"

        else
          # named area already exists
          # this would be used to process alternate names
          item.name_alt
        end
        if ne_a3[ga.iso_3166_a3].nil?
          ne_a3.merge!(ga.iso_3166_a3 => ga)
        end

        ne_names.merge!(names_key => ga)
        ne_ids.merge!(ga.neID => ga)
        ne_a2.merge!(ga.iso_3166_a2 => ga) if ga.iso_3166_a2 =~ /\A[A-Z]{2}\z/
      end
    }
  end

  if iso != nil?
    iso.each { |line|
      # this section is for capturing country names and iso_a2 codes from the "country_names_and_code_elements" file.
      if line.squish.length > 6 # minimum line size to contain useful data

        # break down the useful data
        parts       = line.split(';')
        nation_code = parts[1].squish # clean off the line extraneous white space
        nation_name = parts[0].titlecase

        # search by A2 nation code
        if ne_a2[nation_code].nil?
          # We will need to create new @global_keys records so that we can check for typing anomalies and
          # misplaced areas later, and so that we have the iso codes up to which to match during lvl4 processing.

          if !(nation_name =~ /Country Name/) # drop the headers on the floor
            ga = GeographicArea.new(parent:               earth,
                                    # if we create records here, they will specifically
                                    # *not* be TDWG records
                                    # or GADM records
                                    tdwg_parent:          nil,
                                    name:                 nation_name,
                                    iso_3166_a2:          nation_code,
                                    data_origin:          ISO_3166_1_2,
                                    geographic_area_type: gat5)

            ga.level0 = ga
            ne_a2.merge!(nation_code => ga) if !(ga.nil?)

            names_key = {'l0' => ga.name}
            if ne_names[names_key].nil?
              ne_names.merge!(names_key => ga)
            else
              names_key
            end

            puts "'#{nation_code}' for Country of #{nation_name}\t\tAdded. (ISO)"
          end
        else
          ga = ne_a2[nation_code]
          # found a record with the right name
          # puts "'#{nation_code}' for #{ga.geographic_area_type.name} of #{nation_name}\t\tMatched #{ga.geographic_area_type.name} of #{ga.name}."
        end
      end
    }

    #puts 'Saving ISO-3166-1-alpha-2 countries and codes.'
    #ne_names.each { |key, area|
    # puts "Saving #{area.name}"
    # area.save
    #}
  end

  if gadm2 != nil
    # we are processing non-TDWG data; right now, that is gadm data
    # this processing is specifically for GADM2

    gadm_example = {"OBJECTID"   => 1,
                    "ID_0"       => 1,
                    "ISO"        => "AFG",

                    "NAME_0"     => "Afghanistan",

                    "ID_1"       => 12,
                    "NAME_1"     => "Jawzjan",
                    "VARNAME_1"  => "Jaozjan|Jozjan|Juzjan|Jouzjan|Shibarghan",
                    "NL_NAME_1"  => "",
                    "HASC_1"     => "AF.JW",
                    "CC_1"       => "",
                    "TYPE_1"     => "Velayat",
                    "ENGTYPE_1"  => "Province",
                    "VALIDFR_1"  => "19640430",
                    "VALIDTO_1"  => "198804",
                    "REMARKS_1"  => "",

                    "ID_2"       => 129,
                    "NAME_2"     => "Khamyab",
                    "VARNAME_2"  => "",
                    "NL_NAME_2"  => "",
                    "HASC_2"     => "AF.JW.KM",
                    "CC_2"       => "",
                    "TYPE_2"     => "",
                    "ENGTYPE_2"  => "",
                    "VALIDFR_2"  => "Unknown",
                    "VALIDTO_2"  => "Present",
                    "REMARKS_2"  => "",

                    "ID_3"       => 0,
                    "NAME_3"     => "",
                    "VARNAME_3"  => "",
                    "NL_NAME_3"  => "",
                    "HASC_3"     => "",
                    "TYPE_3"     => "",
                    "ENGTYPE_3"  => "",
                    "VALIDFR_3"  => "",
                    "VALIDTO_3"  => "",
                    "REMARKS_3"  => "",

                    "ID_4"       => 0,
                    "NAME_4"     => "",
                    "VARNAME_4"  => "",
                    "TYPE4"      => "",
                    "ENGTYPE4"   => "",
                    "TYPE_4"     => "",
                    "ENGTYPE_4"  => "",
                    "VALIDFR_4"  => "",
                    "VALIDTO_4"  => "",
                    "REMARKS_4"  => "",

                    "ID_5"       => 0,
                    "NAME_5"     => "",
                    "TYPE_5"     => "",
                    "ENGTYPE_5"  => "",

                    "Shape_Leng" => 1.30495037416,
                    "Shape_Area" => 0.0798353069113}

    if divisions == true
      # this section is specifically, and only, for gathering the English names of the divisions from level_1 and level_2 named areas

      gadm2.each { |item|

        s0 = "#{item['OBJECTID']}: "

        lvl1_type = item['ENGTYPE_1']
        if lvl1_type != ''
          if @lvl0_items[lvl1_type].nil?
            @lvl0_items[lvl1_type] = 1
          else
            @lvl0_items[lvl1_type] += 1
          end
          s1 = "\'#{lvl1_type}\': #{@lvl0_items[lvl1_type]}, "
        else
          s1 = ''
        end

        lvl2_type = item['ENGTYPE_2']
        if lvl2_type != ''
          if @lvl0_items[lvl2_type].nil?
            @lvl0_items[lvl2_type] = 1
          else
            @lvl0_items[lvl2_type] += 1
          end
          s2 = "\'#{lvl2_type}\': #{@lvl0_items[lvl2_type]}, "
        else
          s2 = ''
        end

=begin
        lvl3_type = item['ENGTYPE_3']
        if lvl3_type != ''
          if @lvl0_items[lvl3_type].nil?
            @lvl0_items[lvl3_type] = 1
          else
            @lvl0_items[lvl3_type] += 1
          end
          s3 = "\'#{lvl3_type}\': #{@lvl0_items[lvl3_type]}, "
        else
          s3 = ''
        end

        lvl4_type = item['ENGTYPE_4']
        if lvl4_type != ''
          if @lvl0_items[lvl4_type].nil?
            @lvl0_items[lvl4_type] = 1
          else
            @lvl0_items[lvl4_type] += 1
          end
          s4 = "\'#{lvl4_type}\': #{@lvl0_items[lvl4_type]}, "
        else
          s4 = ''
        end

        lvl5_type = item['ENGTYPE_5']
        if lvl5_type != ''
          if @lvl0_items[lvl5_type].nil?
            @lvl0_items[lvl5_type] = 1
          else
            @lvl0_items[lvl5_type] += 1
          end
          s5 = "\'#{lvl5_type}\': #{@lvl0_items[lvl5_type]}, "
        else
          s5 = ''
        end
        puts "#{s0} #{item['NAME_0']} => #{s1}#{s2}#{s3}#{s4}#{s5}"
=end
        # puts "#{s0} #{item['NAME_0']} => #{s1}#{s2}"

      }

      @lvl0_items.sort_by { |name, count| count }.each { |item| puts "\"#{item[0]}\": #{item[1]}" }
      # breakpoint.save
    end

    @global_keys, @lvl0_items, @lvl1_items, @lvl2_items, @lvl3_items, @lvl4_items, @lvl5_items = {}, {}, {}, {}, {}, {}, {}, {}

    last_record = false

    index = 0
    gadm2.each { |item|

      index   += 1
      # next if index < 217000

      l0_name = item['NAME_0'] # two_tick(item['NAME_0'].titlecase)
      l0_iso  = item['ISO']
      l0_id   = item['ID_0']

      gadm_id = item['OBJECTID']
      l1_id   = item['ID_1']
      l2_id   = item['ID_2']
      l3_id   = item['ID_3']
      l4_id   = item['ID_4']
      l5_id   = item['ID_5']

      id_vector = [l0_id, l1_id, l2_id]

      # l0 always has a name
      l1_name   = item['NAME_1'].gsub(/\n/, ' ') # two_tick(item['NAME_1'].titlecase.gsub(/\n/, ' '))
      l1_type   = item['ENGTYPE_1']
      l2_name   = (l2_id == 0) ? '' : item['NAME_2'].gsub(/\n/, ' ') # two_tick(item['NAME_2'].titlecase.gsub(/\n/, ' '))
      l2_type   = item['ENGTYPE_2']
      l3_name   = (l3_id == 0) ? '' : item['NAME_3'].gsub(/\n/, ' ') # two_tick(item['NAME_3'].titlecase.gsub(/\n/, ' '))
      l3_type   = item['ENGTYPE_3']
      l4_name   = (l4_id == 0) ? '' : item['NAME_4'].gsub(/\n/, ' ') # two_tick(item['NAME_4'].titlecase.gsub(/\n/, ' '))
      l4_type   = item['ENGTYPE_4']
      l5_name   = (l5_id == 0) ? '' : item['NAME_5'].gsub(/\n/, ' ') # two_tick(item['NAME_5'].titlecase.gsub(/\n/, ' '))
      l5_type   = item['ENGTYPE_5']

      record_key = {'l0' => l0_name,
                    'l1' => l1_name,
                    'l2' => l2_name}

      if ne_names[record_key].nil?
      else
        next # we have processed a record containing this information, so we skip this one
      end

      if (gadm_id % 1000) == 238
        i5 = l5_name
        s5 = i5.empty? ? '' : ("#{l5_type} of \"" + i5 + "\", ")
        i4 = l4_name
        s4 = i4.empty? ? '' : ("#{l4_type} of \"" + i4 + "\", ")
        i3 = l3_name
        s3 = i3.empty? ? '' : ("#{l3_type} of \"" + i3 + "\", ")
        i2 = l2_name
        s2 = i2.empty? ? '' : ("#{l2_type} of \"" + i2 + "\", ")
        i1 = l1_name
        s1 = i1.empty? ? '' : ("#{l1_type} of \"" + i1 + "\", ")
        a1 = "#{s5}#{s4}#{s3}#{s2}#{s1}\"#{l0_name}\"."
        a1 = "#{s5}#{s2}#{s1}\"#{l0_name}\"."
        puts "#{gadm_id}:'#{l0_iso}' #{a1}"
        # puts "#{gadm_id}:"
      end

      # build lvl0 key value from lvl0 data

      l0_key    = {
        'ID_0'   => l0_id,
        'ISO'    => l0_iso,
        'NAME_0' => l0_name
      }
      names_key = {'l0' => l0_name}

      if !(l0_iso =~ /\A[A-Z]{3}\z/)
        next # just bail on the record
      end

      # look in ne_a3 for an existing record by iso_a3
      #ga = ne_a3[l0_iso]
      #look in ne_names for an existing record by name-set
      ga = ne_names[names_key]
      if ga.nil?

        # names_key = {'l0' => 'Åland'}
        # if not in name list, stick this one in the name list
        # puts "Adding Level 0: #{names_key}."
        # create a record for the zero level, and the @global_keys list
        ga = GeographicArea.new(parent:               earth,
                                iso_3166_a3:          l0_iso,
                                data_origin:          GADM2_0,
                                # when the record is first created for this named place
                                gadmID:               nil,
                                geographic_area_type: gat5,
                                name:                 l0_name)
        ne_names.merge!({names_key => ga})
        ne_ga = ne_a3[l0_iso]
        if ne_ga.nil?
          # is not in table
          ne_a3.merge!({l0_iso => ga})
        else
          # found an entry, what do we have to update?
          l0_iso
        end
      else # found in name-set, update for gadm
        # data_origin will already have been set
        ga.iso_3166_a3 = l0_iso if ga.iso_3166_a3.nil?
        if ga.iso_3166_a3 != l0_iso
          # a3 conflict
          l0_iso
        end
      end
      # l0 is now the object we want
      l0 = ga

      if (l1_name.empty? and l2_name.empty? and l3_name.empty? and l4_name.empty? and l5_name.empty?)
        ga.gadmID = gadm_id
      end
      if l1_name.empty?
        if !l2_name.empty?
          if l2_name == 'Dhaualagiri'
            dhaualagiri += 1
          else
            puts item.attributes
          end
        end
      end

      # put the item in the lvl0 list
      place = {l0_key => ga}
      @lvl0_items.merge!(place)
      # and the @global_keys list
      @global_keys.merge!(place)
      # yes, this *is* the same as parent
      ga.level0 = ga
      l0        = ga

      if l1_name.empty?
        # nothing to do
        # make the parent of level 2 (extant?) the level 0 area
        # thereby skipping the level 1 emptiness
        l1 = l0

      else

        # process level 1, using level 0 as parent

=begin
                    "ID_1"       => 12,
                    "NAME_1"     => "Jawzjan",
                    "VARNAME_1"  => "Jaozjan|Jozjan|Juzjan|Jouzjan|Shibarghan",
                    "NL_NAME_1"  => "",
                    "HASC_1"     => "AF.JW",
                    "CC_1"       => "",
                    "TYPE_1"     => "Velayat",
                    "ENGTYPE_1"  => "Province",
                    "VALIDFR_1"  => "19640430",
                    "VALIDTO_1"  => "198804",
                    "REMARKS_1"  => "",
=end

        l1_key    = {
          'ID_1'      => l1_id,
          'NAME_1'    => l1_name,
          'VARNAME_1' => item['VARNAME_1'],
          'NL_NAME_1' => item['NL_NAME_1'],
          'HASC_1'    => item['HASC_1'],
          'CC_1'      => item['CC_1'],
          'TYPE_1'    => item['TYPE_1'],
          'ENGTYPE_1' => item['ENGTYPE_1'],
          'VALIDFR_1' => item['VALIDFR_1'],
          'VALIDTO_1' => item['VALIDTO_1'],
          'REMARKS_1' => item['REMARKS_1']
        }
        names_key = {'l0' => l0_name,
                     'l1' => l1_name}

        # ga = @lvl1_items[l1_key]
        ga        = ne_names[names_key]
        if ga.nil?
          # puts "Adding Level 1: #{names_key}."
          # create a record for level 1, and the @global_keys list
          ga = GeographicArea.new(parent:               l0,
                                  name:                 l1_name,
                                  data_origin:          GADM2_1,
                                  # when the record is first created for this named place
                                  gadmID:               gadm_id,
                                  geographic_area_type: add_gat(item['ENGTYPE_1']))
          # put the item in the name list
          ne_names.merge!({names_key => ga})
          place = {l1_key => ga}
          @lvl1_items.merge!(place)
          # and the @global_keys list
          @global_keys.merge!(place)
        else # found a record at level 1; been here before
          # nothing to do
          # puts "Found  Level 1: #{names_key}."
          l1_name
        end
        ga.gadm_valid_from = item['VALIDFR_1']
        ga.gadm_valid_to   = item['VALIDTO_1']

        if (l2_name.empty? and l3_name.empty? and l4_name.empty? and l5_name.empty?)
          ga.gadmID = gadm_id
        end

        ga.level0 = ga.parent
        ga.level1 = ga
      end
      l1 = ga

      if l2_name.empty?
        # nothing to do
      else

        # process level 2, using level 1 as parent

        l2_key    = {
          'ID_2'      => l2_id,
          'NAME_2'    => l2_name,
          'VARNAME_2' => item['VARNAME_2'],
          'NL_NAME_2' => item['NL_NAME_2'],
          'HASC_2'    => item['HASC_2'],
          'CC_2'      => item['CC_2'],
          'TYPE_2'    => item['TYPE_2'],
          'ENGTYPE_2' => item['ENGTYPE_2'],
          'VALIDFR_2' => item['VALIDFR_2'],
          'VALIDTO_2' => item['VALIDTO_2'],
          'REMARKS_2' => item['REMARKS_2']
        }
        names_key = {'l0' => l0_name,
                     'l1' => l1_name,
                     'l2' => l2_name}

        # l2 = @lvl2_items[l2_key]
        ga        = ne_names[names_key]
        if ga.nil?
          # puts "Adding Level 2: #{names_key}."
          # create a record for level 2, and the @global_keys list
          ga = GeographicArea.new(parent:               l1,
                                  name:                 l2_name,
                                  data_origin:          GADM2_2,
                                  # when the record is first created for this named place
                                  gadmID:               nil,
                                  geographic_area_type: add_gat(item['ENGTYPE_2']))

          ga.gadm_valid_from = item['VALIDFR_2']
          ga.gadm_valid_to   = item['VALIDTO_2']
          ga.level0          = ga.parent.parent
          ga.level1          = ga.parent
          ga.level2          = ga

          # put the item in the lvl2 list
          place              = {l2_key => ga}
          @lvl2_items.merge!(place)
          # and the @global_keys list
          @global_keys.merge!(place)
          ne_names.merge!({names_key => ga})

        else
          # nothing to do
          # puts "Found  Level 2: #{names_key}."
          l2_name
        end

        if (l3_name.empty? and l4_name.empty? and l5_name.empty?)
          ga.gadmID = gadm_id
        end

      end
      l2 = ga

=begin
      if l3_name.empty?
        # nothing to do
      else
        # process level 3, using level 2 as parent

        l3 = @lvl3_items[l2_name]
        if l3.nil?
          # create a record for level 3, and the @global_keys list
          ga    = GeographicArea.new(parent:               l2,
                                     name:                 l3_name,
                                     iso_3166_a3:          item['ISO'],
                                     geographic_area_type: add_gat(item['ENGTYPE_3']))
          # put the item in the lvl0 list
          place = {l3_name => ga}
          @lvl3_items.merge!(place)
          # and the @global_keys list
          @global_keys.merge!(place)
          l3 = ga
        else
          # nothing to do
        end
      end

      if l4_name.empty?
        # nothing to do
      else
        # process level 4, using level 3 as parent

        l4 = @lvl4_items[l4_name]
        if l4.nil?
          # create a record for level 4, and the @global_keys list
          ga    = GeographicArea.new(parent:               l3,
                                     name:                 l4_name,
                                     iso_3166_a3:          item['ISO'],
                                     geographic_area_type: add_gat(item['ENGTYPE_4']))
          # put the item in the lvl0 list
          place = {l4_name => ga}
          @lvl4_items.merge!(place)
          # and the @global_keys list
          @global_keys.merge!(place)
          l4 = ga
        else
          # nothing to do
        end
      end

      if l5_name.empty?
        # nothing to do
      else
        # process level 5, using level 4 as parent

        l5 = @lvl5_items[l5_name]
        if l5.nil?
          # create a record for level 5, and the @global_keys list
          ga    = GeographicArea.new(parent:               l4,
                                     name:                 l5_name,
                                     iso_3166_a3:          item['ISO'],
                                     geographic_area_type: add_gat(item['ENGTYPE_5']))
          # put the item in the lvl0 list
          place = {l5_name => ga}
          @lvl5_items.merge!(place)
          # and the @global_keys list
          @global_keys.merge!(place)
          l5 = ga
        else
          # nothing to do
        end
      end
=end
    } # of GADM processing
  end

  if lvl1 != nil

    gat1  = GeographicAreaType.where(name: 'Level 1').first
    gat2  = GeographicAreaType.where(name: 'Level 2').first
    gat3  = GeographicAreaType.where(name: 'Level 3').first
    gat4  = GeographicAreaType.where(name: 'Level 4').first

    #tl1 = GARecord.new(attributes: item.attributes)

    # processing the TDWG2 level files into memory

    index = 0
    lvl1.each { |item|

      index     += 1
      l1n       = item['LEVEL1_NAM'].titlecase
      l1c       = item['LEVEL1_COD'].to_s + '----'
      names_key = {'l0' => l1n}

      puts "1-#{index}:\t\t#{l1c} for #{l1n}."

      ga        = GeographicArea.new(parent:               earth,
                                     tdwg_parent:          earth,
                                     tdwgID:               l1c,
                                     data_origin:          TDWG2_L1,
                                     name:                 l1n,
                                     geographic_area_type: gat1)
      ga.level0 = ga
      @lvl1_items.merge!(l1c => ga)
      @global_keys.merge!(ga.tdwgID => ga)

      ne_ga = ne_names[names_key]
      if ne_ga.nil?
        # if not in name list, stick this one in the name list
        ne_names.merge!({names_key => ga})
      else
        l1n
      end
    }

    index = 0
    lvl2.each { |item|

      index     += 1
      l2p       = @lvl1_items[item['LEVEL1_COD'].to_s + '----']
      l2n       = item['LEVEL2_NAM'].titlecase # two_tick(item['LEVEL2_NAM'].titlecase)
      l2c       = item['LEVEL2_COD'].to_s + '---'
      names_key = {'l0' => l2p.name,
                   'l1' => l2n}

      puts "2-#{index}:\t\t#{l2c} for #{l2n} in #{l2p.name}."

      ga        = GeographicArea.new(parent:               l2p,
                                     tdwg_parent:          l2p,
                                     tdwgID:               l2c,
                                     name:                 l2n,
                                     data_origin:          TDWG2_L2,
                                     geographic_area_type: gat2)
      ga.level0 = l2p
      ga.level1 = ga
      @lvl2_items.merge!(l2c => ga)
      @global_keys.merge!(ga.tdwgID => ga)

      ne_ga = ne_names[names_key]
      if ne_ga.nil?
        # if not in name list, stick this one in the name list
        ne_names.merge!({names_key => ga})
      else
        l2n
      end
    }

    index = 0
    lvl3.each { |item|

      index       += 1
      update_tdwg = false
      l2c         = item['LEVEL2_COD'].to_s
      l3p         = @lvl2_items[l2c + '---']
      l3n         = item['LEVEL3_NAM'] # two_tick(item['LEVEL3_NAM'].titlecase)
      l3a3        = item['LEVEL3_COD']
      l3c         = l2c + l3a3
      names_key   = {'l0' => l3p.parent.name,
                     'l1' => l3p.name,
                     'l2' => l3n}

      puts "3-#{index}:\t\t#{l3c} for #{l3n} in #{l3p.name}."

      # we are most likely to find a match by name, so
      # we check names first.
      ne_ga = ne_names[names_key]

      if ne_ga.nil?
        ga = @lvl3_items[l3c]
        if ga.nil?
          # new TDWG-only record
          ga        = GeographicArea.new(parent:               l3p,
                                         tdwg_parent:          l3p,
                                         tdwgID:               l3c,
                                         name:                 l3n,
                                         data_origin:          TDWG2_L3,
                                         geographic_area_type: gat3)
          ga.level0 = l3p.parent
          ga.level1 = l3p
          ga.level2 = ga
          @lvl3_items.merge!(l3c => ga)
          @global_keys.merge!(ga.tdwgID => ga)
          ne_names.merge!({names_key => ga})

        else
          # then try by iso a3
          ga = ne_a3[l3c]
          if ga.nil?
            update_tdwg = false
          else
            # found a record by iso_a3
            # Be suspicious, VERY suspicious...
            if ga.name == l3n
              # if it has the same name
              # found a named record: is it sane?
              # TODO: It appears to be qualified, what else can we test, to disqualify it?
              update_tdwg = true
            end
          end
        end
      else
        update_tdwg = true
      end

      if update_tdwg
        ga.tdwgID      = l3c
        ga.tdwg_parent = l3p
      end
    }

    # Before we process the lvl4 data, we will process the iso codes information, so that the iso codes in lvl4 will
    # have some meaning when we process *them*.

    # add, where possible, ISO 3166 country codes

    index = 0
    lvl4.each { |item|
      # When processing lvl4, there are two different ways we need to process the line data:
      #   If this entry has a sub-code of 'OO', it should be represented in one of the earlier levels

      # puts item.attributes

      index          += 1

      # isolate the name
      this_area_name = item['Level_4_Na'] # two_tick(item['Level_4_Na'].titlecase)
      # and the iso code of this area
      iso_a3         = item['Level3_cod']
      iso_a2         = item['ISO_Code']
      l1c            = item['Level1_cod'].to_s + '----'
      l2c            = item['Level2_cod'].to_s + '---'
      l3c_a3         = item['Level3_cod']
      l3c            = item['Level2_cod'].to_s + l3c_a3
      l4c_a2         = item['Level4_2']
      l4c            = item['Level2_cod'].to_s + item['Level4_cod']
      l4n            = this_area_name


      case iso_a2
        when 'UK'
          iso_a2 = 'GB'
      end

      # find the nation by its country code
      nation = ne_a3[iso_a3]
      if nation.nil?
        nation = ne_a2[iso_a2]
      else
        # found a possible iso match
        if nation.name == this_area_name
          this_area_name
        else
          nation = ne_a2[iso_a2]
        end
      end

      l3_ga = @lvl3_items[l3c]

      if nation.nil?
        # failed to find a parent
        next
      end

      if this_area_name == nation.name
        # country-level shape has been accounted for
        if l3c_a3 == nation.iso_3166_a3
          next
        end
      end

      names_key = {'l0' => @lvl1_items[l1c].name,
                   'l1' => @lvl2_items[l2c].name,
                   'l2' => l3_ga.name,
                   'l3' => this_area_name}

=begin
# here are some problem level 4 records:
{"ISO_Code"=>"UK", "Level_4_Na"=>"Channel Is.", "Level4_cod"=>"FRA-CI", "Level4_2"=>"CI", "Level3_cod"=>"FRA", "Level2_cod"=>12, "Level1_cod"=>1}
{"ISO_Code"=>"UK", "Level_4_Na"=>"Great Britain", "Level4_cod"=>"GRB-OO", "Level4_2"=>"OO", "Level3_cod"=>"GRB", "Level2_cod"=>10, "Level1_cod"=>1}
{"ISO_Code"=>"UK", "Level_4_Na"=>"Northern Ireland", "Level4_cod"=>"IRE-NI", "Level4_2"=>"NI", "Level3_cod"=>"IRE", "Level2_cod"=>10, "Level1_cod"=>1}
{"ISO_Code"=>"AN", "Level_4_Na"=>"Netherlands Leeward Is.", "Level4_cod"=>"LEE-NL", "Level4_2"=>"NL", "Level3_cod"=>"LEE", "Level2_cod"=>81, "Level1_cod"=>8}
{"ISO_Code"=>"TP", "Level_4_Na"=>"East Timor", "Level4_cod"=>"LSI-ET", "Level4_2"=>"ET", "Level3_cod"=>"LSI", "Level2_cod"=>42, "Level1_cod"=>4}
{"ISO_Code"=>"AN", "Level_4_Na"=>"Bonaire", "Level4_cod"=>"NLA-BO", "Level4_2"=>"BO", "Level3_cod"=>"NLA", "Level2_cod"=>81, "Level1_cod"=>8}
{"ISO_Code"=>"AN", "Level_4_Na"=>"Curaçao", "Level4_cod"=>"NLA-CU", "Level4_2"=>"CU", "Level3_cod"=>"NLA", "Level2_cod"=>81, "Level1_cod"=>8}
{"ISO_Code"=>"PI", "Level_4_Na"=>"Paracel Is.", "Level4_cod"=>"SCS-PI", "Level4_2"=>"PI", "Level3_cod"=>"SCS", "Level2_cod"=>41, "Level1_cod"=>4}
{"ISO_Code"=>"SP", "Level_4_Na"=>"Spratly Is.", "Level4_cod"=>"SCS-SI", "Level4_2"=>"SI", "Level3_cod"=>"SCS", "Level2_cod"=>41, "Level1_cod"=>4}
{"ISO_Code"=>"YU", "Level_4_Na"=>"Kosovo", "Level4_cod"=>"YUG-KO", "Level4_2"=>"KO", "Level3_cod"=>"YUG", "Level2_cod"=>13, "Level1_cod"=>1}
{"ISO_Code"=>"YU", "Level_4_Na"=>"Montenegro", "Level4_cod"=>"YUG-MN", "Level4_2"=>"MN", "Level3_cod"=>"YUG", "Level2_cod"=>13, "Level1_cod"=>1}
{"ISO_Code"=>"YU", "Level_4_Na"=>"Serbia", "Level4_cod"=>"YUG-SE", "Level4_2"=>"SE", "Level3_cod"=>"YUG", "Level2_cod"=>13, "Level1_cod"=>1}
=end

      puts "4-#{index}:\t\t#{l4c} for #{this_area_name} in #{nation.name}."

      # find the matching name-set record by name (not likely)
      ga = ne_names[names_key]
      if ga.nil?
        # failed to find an area by this name in the TDWG data, so we need to create one
        # so we set the parent to the object pointed to by the level 3 code
        ga        = GeographicArea.new(parent:               l3_ga,
                                       tdwg_parent:          l3_ga,
                                       tdwgID:               l4c,
                                       name:                 this_area_name,
                                       iso_3166_a2:          nil,
                                       data_origin:          TDWG2_L4,
                                       # we show this is from the TDWG data, *not* the iso data
                                       geographic_area_type: gat4)
        # even if nation is nil, this will do what we want.
        ga.level0 = nation
        ga.level1 = l3_ga.parent
        ga.level2 = l3_ga
        @lvl4_items.merge!(l4c => ga)
        @global_keys.merge!(ga.tdwgID => ga)
        ne_names.merge!({names_key => ga})

      else
        this_area_name
      end

      if nation.nil?

        puts "#{nation.nil? ? 'Unmatchable record' : nation.name}::#{item.attributes}"
      else
        # puts nation.name
      end
    }
  end

  puts 'Saving NaturalEarth records...'

  index = 0
  # breakpoint.save

  puts 'Saving by name.'
  ne_names.each { |key, area|
    if area.new_record?
      index += 1
      area.save!
      puts "By name - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving by neID.'
  ne_ids.each { |key, area|
    if area.new_record?
      index += 1
      area.save!
      puts "By id   - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving by A3.'
  ne_a3.each { |key, area|
    if area.new_record?
      index += 1
      area.save!
      puts "By A3   - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving by adm0.'
  ne_adm0.each { |key, area|
    if area.new_record?
      index += 1
      area.save!
      puts "By adm0 - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving by A2.'
  ne_a2.each { |key, area|
    if area.new_record?
      index += 1
      area.save!
      puts "By A2   - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving Level 0 areas.'
  @lvl0_items.each { |key, area|
    area.data_origin = GADM2_0 if area.data_origin.nil?
    if area.new_record?
      index += 1
      area.save!
      puts "By lvl0 - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving Level 1 areas.'
  @lvl1_items.each { |key, area|
    area.data_origin = GADM2_1 if area.data_origin.nil?
    if area.new_record?
      index += 1
      area.save!
      puts "By lvl1 - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving Level 2 areas.'
  @lvl2_items.each { |key, area|
    area.data_origin = GADM2_2 if area.data_origin.nil?
    if area.new_record?
      index += 1
      area.save!
      puts "By lvl2 - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

  puts 'Saving Level 3 areas.'
  @lvl3_items.each { |key, area|
    area.data_origin = GADM2_3 if area.data_origin.nil?
    if area.new_record?
      index += 1
      area.save!
      puts "By lvl3 - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end

    # rebuilding the awesome_nested_set-edness
    # GeographicArea.rebuild!
  }
=begin

  puts 'Saving Level 4 areas.'
  @lvl4_items.each { |key, area|
    area.save
    @global_keys.delete(area.name)
  }

  puts 'Saving Level 5 areas.'
  @lvl5_items.each { |key, area|
    area.save
    @global_keys.delete(area.name)
  }
=end

  # what is left over?
  puts 'Saving non-Level(0, 1, 2) areas.'
  @global_keys.each { |key, area|
    if area.new_record?
      index += 1
      area.save!
      puts "By key  - #{index}: #{area.geographic_area_type.name} of #{area.name} from #{area.data_origin}."
    end
  }

end

def read_csv(file)

  # data = CSV.open(file)

  data = CSV.read(file, options = {headers: true})

  record    = GeographicArea.new
  area_type = GeographicAreaType.new
  data.each { |row|

    puts row

    case file
      when /USA_adm0/
        record    = GeographicArea.new(parent_id:  0,
                                       name:       row.field('NAME_ENGLISH'),
                                       country_id: row.field('PID'))
        area_type = GeographicAreaType.where(name: 'Country')[0]
        if area_type.nil?
          at = GeographicAreaType.new(name: 'Country')
          at.save
          area_type = at
        end
      when /USA_adm1/
        record    = GeographicArea.new(parent_id:  row.field('ID_0'),
                                       name:       row.field('NAME_1'),
                                       state_id:   row.field('ID_1'),
                                       country_id: row.field('ID_0'))
        area_type = GeographicAreaType.where(name: row.field('TYPE_1'))[0]
        if area_type.nil?
          at = GeographicAreaType.new(name: row.field('TYPE_1'))
          at.save
          area_type = at
        end
      when /USA_adm2/
        record    = GeographicArea.new(parent_id:  row.field('ID_1'),
                                       name:       row.field('NAME_2'),
                                       state_id:   row.field('ID_1'),
                                       country_id: row.field('ID_0'),
                                       county_id:  row.field('ID_2'))
        area_type = GeographicAreaType.where(name: row.field('TYPE_2'))[0]
        if area_type.nil?
          at = GeographicAreaType.new(name: row.field('TYPE_2'))
          at.save
          area_type = at
        end
      else

    end
    record.geographic_area_type = area_type
    record.save
  }
end

def add_gat(gat)
  # extracted out to enable single insert

  area_type = @gat_list[gat]
  if area_type.nil?
    area_type = GeographicAreaType.new(name: gat)
    area_type.save
    @gat_list.merge!(gat => area_type)
  end
  area_type
end

def build_gat_table

  # create our list
  l_var     = 'Unknown'
  @gat_list = {}

  ['Planet',
   'Level 0',
   'Continent',
   'Level 1',
   'Subcontinent',
   'Level 2',
   'Country',
   'Level 3',
   'State',
   'Level 4',
   'Federal District',
   'County',
   'Borough',
   'Census Area',
   'Municipality',
   'Municipality/Municipal Council',
   'City And Borough',
   'City And County',
   'District',
   'Water body',
   'Parish',
   'Independent City',
   'Province',
   'Ward',
   'Prefecture',
   l_var,
   'Shire'].each { |item|
    area_type = GeographicAreaType.where(name: item).first
    if area_type.nil?
      area_type = GeographicAreaType.new(name: item)
      area_type.save
    end
    @gat_list.merge!(item => area_type)
  }

  # add as required from NaturalEarth list
  ne_divisions

  # add as required from GADM list
  gadm_divisions

  # make special cases
  @gat_list.merge!('' => @gat_list[l_var])
  @gat_list.merge!(nil => @gat_list[l_var])
end

def ne_divisions

  # create our list
  ['Sovereign country',
   'Indeterminate',
   'Disputed',
   'Lease'].each { |item|
    area_type = GeographicAreaType.where(name: item).first
    if area_type.nil?
      area_type = GeographicAreaType.new(name: item)
      area_type.save
    end
    @gat_list.merge!(item => area_type)
  }
end

def gadm_divisions
  ['Reef',
   'Metropolitan Borough (city)',
   'Autonomous Okurg',
   'Administrative Area',
   'Territorial Unit',
   'Autonomous Sector',
   'Conservancy',
   'City and County',
   'National District',
   'Capital City',
   'Autonomous Commune',
   'Commune and Prefecture',
   'Capital',
   'Capital Territory',
   'Unitary Authority (county)',
   'Autonomous Territory',
   'National Territory',
   'Neutral City',
   'Capital District',
   'City and Borough',
   'Outlying Island',
   'Island|Atoll',
   'Autonomous Monastic State',
   'Ward',
   'London Borough (royal)',
   'Directly Governed City',
   'Island Area',
   'London Borough (city)',
   'City Municipality',
   'Autonomous Island',
   'Territorial Authority',
   'Statutory city',
   'Metropolitan District',
   'Town Council',
   'Municipal District',
   'Autonomous City',
   'Economic Prefecture',
   'Préfecture',
   'Unitary District (city)',
   'Special Municipality',
   'Independent Town',
   'Lake',
   'Dependency',
   'Atoll',
   'Island Group',
   'Water Body',
   'Special region',
   'Area',
   'Metropolitan County',
   'Special Administrative Region',
   'Special Region|Zone',
   'Special City',
   'Special district',
   'National Park',
   'Reserve',
   'Island Council',
   'Emirate',
   'Urban',
   'Municipality|Prefecture',
   'Unitary Authority (city)',
   'Quarter',
   'Census Area',
   'Assembly',
   'Island',
   'United County',
   'Statutory City',
   'Centrally Administered Area',
   'Rural City',
   'Municipality / Mun. Council',
   'Automonous Region',
   'Borough',
   'United Counties',
   'Corregimiento Departamento',
   'Capital Region',
   'League',
   'Unitary Authority (wales',
   'Principality',
   'Waterbody',
   'Special Ward',
   'Capital Metropolitan City',
   'Unitary District',
   'Municipality/Municipal Council',
   'London Borough',
   'Commissiary',
   'Raion',
   'Municipality|Governarate',
   'Mukim',
   'Administrative County',
   'Community Government Council',
   'Sector',
   'Federal District',
   'Autonomous Republic',
   'Municipal district',
   'Unitary Authority',
   'Aboriginal Council',
   'Not Classified',
   'Metropolitan City',
   'Chef-Lieu-Wilaya',
   'Regional Municipality',
   'Independent City',
   'District Municipality',
   'Sub-prefecture',
   'Sub-Province',
   'District Council',
   'Metropolis',
   'Intendancy',
   'Headquarter',
   "Mis'ka Rada",
   'Ressort',
   'National Capital Area',
   'Neighbourhood Democratic',
   'District|Regencies',
   'Urban Prefecture',
   'State|Federal State',
   'Water body',
   'Union Territory',
   'Sub-district',
   'Indigenous Territory',
   'City council',
   'Constituency',
   'Commune-Cotiere',
   'Part',
   'Minor district',
   'Entity',
   'Kingdom',
   'Sub-region',
   'Village',
   'Subregion',
   'Circuit',
   'Town|Municipal',
   'Commune|Municipality',
   'Poblacion',
   'Arrondissement',
   'Autonomous region',
   'Autonomous Prefecture',
   'Delegation',
   'Statistical Region',
   'Sum',
   'Regency',
   'Magisterial District',
   'Voivodeship|Province',
   'Administrative Region',
   'Shire',
   'Regional Council',
   'Republic',
   'Municpality|City Council',
   'Administrative State',
   'Zone',
   'Governorate',
   'Territory',
   'Sub-chief',
   'Circle',
   'Unknown',
   'Local Authority',
   'Regional District',
   'City|Municipality|Thanh Pho',
   'Town',
   'Division',
   'Regional County Municipality',
   'Autonomous Province',
   'Autonomous Region',
   'Prefecture City',
   'Census Division',
   'Traditional Authority',
   'Prefecture',
   'Development Region',
   'Administrative Zone',
   'Canton',
   'Parish',
   'Autonomous Community',
   'City',
   'Commune',
   'County',
   'State',
   'District',
   'Department',
   'Municipality',
   'Region',
   'Province'].each { |item|
    area_type = GeographicAreaType.where(name: item).first
    if area_type.nil?
      area_type = GeographicAreaType.new(name: item)
      area_type.save
    end
    @gat_list.merge!(item => area_type)
  }

end

def two_tick(one_tick)
  return one_tick
=begin
  if one_tick =~ /'/
    return one_tick.gsub("'", "''")
  else
    return one_tick
  end
=end
end
