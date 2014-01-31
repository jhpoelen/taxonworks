# @author Elizabeth Frank <eef@illinois.edu> INHS University of IL
#
# Bibtex - Subclass of Source that represents most references.
#
# TaxonWorks(TW) relies on the bibtex-ruby gem to input or output BibTeX bibliographies,
# and has a strict list of required fields. TW itself only requires that :bibtex_type
# be valid and that one of the attributes in TW_REQ_FIELDS be defined.
# This allows a rapid input of incomplete data, but also means that not all TW Source::Bibtex
# objects can be added to a BibTeX bibliography.
#
# The following information is taken from *BibTeXing*, by Oren Patashnik, February 8, 1988
# http://ftp.math.purdue.edu/mirrors/ctan.org/biblio/bibtex/contrib/doc/btxdoc.pdf
# (and snippets are cut from this document for the attribute descriptions)
#
# BibTeX fields in a BibTex bibliography are treated in one of three ways:
#
# [REQUIRED] Omitting the field will produce a warning message and, rarely, a badly formatted bibliography entry.
# If the required information is not
#       meaningful, you are using the wrong entry type. However, if the required
#       information is meaningful but, say, already included is some other field,
#       simply ignore the warning.
# [OPTIONAL] The field's information will be used if present, but can be omitted
#  without causing any formatting problems. You should include the optional
#       field if it will help the reader.
# [IGNORED] The field is ignored. BibTEX ignores any field that is not required or
#optional, so you can include any fields you want in a bib file entry. It's a
#       good idea to put all relevant information about a reference in its bib file
#       entry - even information that may never appear in the bibliography.
#
# TW will add all non-standard or housekeeping attributes to the bibliography even though
# the data may be ignored.
#
# @!group Ruby standard attributes & our added housekeeping attributes
# @!attribute id [Fixnum]
#   This is the Ruby Active Record ID. When no value is provided for the key attribute and
#   a cross reference is needed, this attribute may be used within the key.
#   @return [Fixnum] the unique identifier of this record in the Source table.
#   @return [nil] means the record does not exist in the database.
#
# @!attribute serial_id [Fixnum]
#   @note not yet implemented!
#   @return [Fixnum] the unique identifier of the serial record in the Serial? table.
#   @return [nil] means the record does not exist in the database.
#
# @!endgroup
#
# @!group BibTeX attributes (based on BibTeX fields)
#
# @!attribute address
#   BibTeX standard field (optional for types: book, inbook, incollection, inproceedings, manual, mastersthesis,
#   phdthesis, proceedings, techreport)
#   Usually the address of the publisher or other type of institution.
#   For major publishing houses, van Leunen recommends omitting the information
#   entirely. For small publishers, on the other hand, you can help the reader by giving the complete address.
#   @return [#String] the address
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute annote
#   BibTeX standard field (ignored by standard processors)
#   An annotation. It is not used by the standard bibliography styles, but
#   may be used by others that produce an annotated bibliography.
#   @return [String] the annotation
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute author
#   BibTeX standard field (required for types: )(optional for types:)
#   A TW required attribute (TW requires a value in one of any of the required attributes.)
#   The name(s) of the author(s), in the format described in the LaTeX book. Names should be formatted as
#   "Last name, FirstName MiddleName". FirstName and MiddleName can be initials. If there are multiple authors,
#   each author name should be separated by the word " and ". It should be noted that all the names before the
#   comma are treated as a single last name.
#   @return [String] the list of author names in BibTeX format
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute editor
#   BibTeX standard field (required for types: )(optional for types:)
#   A TW required attribute (TW requires a value in one of any of the required attributes.)
#   The name(s) of the editor(s), in the format described in the LaTeX book. Names should be formatted as
#   "Last name, FirstName MiddleName". FirstName and MiddleName can be initials. If there are multiple editors,
#   each editor name should be separated by the word " and ". It should be noted that all the names before the
#   comma are treated as a single last name.
#
#   If there is also an author field, then the editor field gives the editor of the book or collection in
#   which the reference appears.
#   @return [String] the list of editor names in BibTeX format
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute booktitle
#   BibTeX standard field (required for types: )(optional for types:)
#   A TW required attribute (TW requires a value in one of the required attributes.)
#   Title of a book, part of which is being cited. See the LaTEX book for how to type titles.
#   For book entries, use the title field instead.
#   @return[String] the title of the book
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute chapter
#   BibTeX standard field (required for types: )(optional for types:)
#   A chapter (or section or whatever) number.
#   @return [String] the chapter or section number.
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute crossref
#   BibTeX standard field (ignored by standard processors)
#   The database key(key attribute) of the entry being cross referenced.
#   This attribute is only set (and saved) during the import process, and is only relevant
#   in a specific bibliography.
#   @return[String] the key of the cross referenced source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute edition
#   BibTeX standard field (required for types: )(optional for types:)
#   The edition of a book(for example, "Second"). This should be an ordinal, and should
#   have the first letter capitalized, as shown here;
#   the standard styles convert to lower case when necessary.
#   @return[String] the edition of the book
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute howpublished
#   BibTeX standard field (required for types: )(optional for types:)
#   How something unusual has been published. The first word should be capitalized.
#   @return[String] a description of how this source was published
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute institution
#   BibTeX standard field (required for types: )(optional for types:)
#   The sponsoring institution of a technical report
#   @return[String] the name of the institution publishing this source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute journal
#   BibTeX standard field (required for types: )(optional for types:)
#   A TW required attribute (TW requires a value in one of the required attributes.)
#   A journal name. Many BibTeX processors have standardized abbreviations for many journals
#   which would be listed in your local BibTeX processor guide. Once this attribute has been
#   normalized against TW Serials, this attribute will contain the full journal name as
#   defined by the Serial object. If you want a preferred abbreviation associated with
#   with this journal, add the abbreviation the serial object.
#   @return[String] the name of the journal (serial) associated with this source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute key
#   BibTeX standard field (may be used in a bibliography for alphabetizing & cross referencing)
#   Used by bibtex-ruby gem method _identifier_ as a default value when no other identifier is present.
#   Used for alphabetizing, cross referencing, and creating a label when the "author" information
#   is missing. This field should not be confused with the key that appears in the \cite (BibTeX/LaTeX)command and at
#   the beginning of the bibliography entry.
#
#   This attribute is only set (and saved) during the import process. It may be generated for output when
#   a bibtex-ruby bibliography is created, but is unlikely to be save to the db.
#   @return[String] the key of this source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute month
#   BibTeX standard field (required for types: )(optional for types:)
#   The month in which the work was published or, for an unpublished work, in which it was written.
#   It should use the standard three-letter abbreviation, as described in Appendix B.1.3 of the LaTeX book.
#   The three-letter lower-case abbreviations are available in _BibTeX::MONTHS_.
#   If month is present there must be a year.
#   @return[String] The three-letter lower-case abbreviation for the month in which this source was published.
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute note
#   BibTeX standard field (required for types: unpublished)(optional for types:)
#   Any additional information that can help the reader. The first word should be capitalized.
#
#   This attribute is used on import, but is otherwise ignored.   Updates to this field are
#   NOT transferred to the associated TW note and not added to any export.
#   @return[String] the BibTeX note associated with this source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute number
#   BibTeX standard field (required for types: )(optional for types:)
#   The number of a journal, magazine, technical report, or of a work in a series.
#   An issue of a journal or magazine is usually identified by its volume and number;
#   the organization that issues a technical report usually gives it a number;
#   and sometimes books are given numbers in a named series.
#
#   This attribute is equivalent to the Species File reference issue.
#   @return[String] the number in a series, issue or technical report number associated with this source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute organization
#   BibTeX standard field (required for types: )(optional for types:)
#   The organization that sponsors a conference or that publishes a manual.
#   @return[String] the organization associated with this source
#   @return [nil] means the attribute is not stored in the database.
#
# @!attribute pages
#   BibTeX standard field (required for types: )(optional for types:)
#   One or more page numbers or range of numbers, such as 42--111 or
#   7,41,73--97 or 43+ (the `+' in this last example indicates pages following
#   that don't form a simple range). To make it easier to maintain Scribe-
#   compatible databases, the standard styles convert a single dash (as in
#   7-33) to the double dash used in TeX to denote number ranges (as in 7--33).
#
#
# @!endgroup
# @!group TW add attributes that are not part of the standard attribute list
# @!endgroup
#
#

class Source::Bibtex < Source
  include SoftValidation

#  include Shared::Notable in source.rb
#
# @!attribute publisher
# @!attribute school
# @!attribute series
# @!attribute title
#   A TW required attribute (TW requires a value in one of the required attributes.)
# @!attribute type
# @!attribute translator - not yet implemented
#   bibtex-ruby gem supports translator, it's not clear whether TW will or not.
# @!attribute volume
# @!attribute year
#   A TW required attribute (TW requires a value in one of the required attributes.)
#   Year must be between 1000 and now + 2 years inclusive
# @!attribute URL
#   A TW required attribute (TW requires a value in one of the required attributes.)
# @!attribute doi - not implemented yet
#   Used by bibtex-ruby gem method identifier
# @!attribute ISBN
#   Used by bibtex-ruby gem method identifier
# @!attribute ISSN
#   Used by bibtex-ruby gem method identifier
# @!attribute LCCN
# @!attribute abstract
# @!attribute keywords
# @!attribute price
# @!attribute copyright
# @!attribute language
# @!attribute contents
# @!attribute stated_year
#   A TW required attribute (TW requires a value in one of the required attributes.)
# @!attribute verbatim
# @!attribute cached
# @!attribute cached_author_year
# @!attribute created_at
# @!attribute created_by - not yet implemented
# @!attribute updated_at
# @!attribute updated_by - not yet implemented
# @!attribute bibtex_type
# @!attribute day
#   If day is present there must be a month and day must be valid for the month.
#
# @!group associations
# @!endgroup
# @!group identifiers
# @!endgroup
# 
#TODO add linkage to serials ==> belongs_to serial
#TODO :update_authors_editor_if_changed? if: Proc.new { |a| a.password.blank? }
# @associations  authors
#   linkage to author roles
  has_many :author_roles, class_name: 'SourceAuthor', as: :role_object
  has_many :authors, -> { order('roles.position ASC') }, through: :author_roles, source: :person # self.author & self.authors should match or one of them should be empty
  has_many :editor_roles, class_name: 'SourceEditor', as: :role_object # ditto for self.editor & self.editors
  has_many :editors, -> { order('roles.position ASC') }, through: :editor_roles, source: :person

#region validations
  validates_inclusion_of :bibtex_type,
    in: ::VALID_BIBTEX_TYPES,
    message: '%{value} is not a valid source type'
  validates_presence_of :year,
    if: '!month.nil?',
    message: 'year is required when month is provided'
  validates_numericality_of :year,
    only_integer: true, greater_than: 999,
    less_than_or_equal_to: Time.now.year + 2,
    allow_nil: true,
    message: 'year must be an integer greater than 999 and no more than 2 years in the future'
  validates_presence_of :month, 
    if: '!day.nil?',
    message: 'month is required when day is provided'
  validates_inclusion_of :month,
    in: ::VALID_BIBTEX_MONTHS,
    allow_nil: true,
    message: ' month'
  validates_numericality_of :day,
    allow_nil: true,
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: Proc.new { |a| Time.utc(a.year, a.month).end_of_month.day },
    :unless => 'year.nil? || month.nil?',
    message: '%{value} is not a valid day for the month provided'

#  validates :url, :format => /\A#{URI::regexp}\z/, allow_nil: true  # this line is essentially the same as below
  # but isn't as clear. Note that both validations allow multiple urls strung together with a ',' provided
  # no spaces are included.
  validates :url, :format => { :with => URI::regexp(%w(http https ftp)),
            message: "[%{value}] is not a valid URL"}, allow_nil: true

  before_validation :check_has_field #,:day_valid? #, :year_valid?
  before_save :set_nomenclature_date
  #TODO before_save set cached values

#endregion validations

  # nil is last by default, exclude it explicitly with another condition if need be
  scope :order_by_nomenclature_date, -> { order(:nomenclature_date) } 

#region soft_validate setup calls

  soft_validate(:sv_has_some_type_of_year, set: :recommended_fields)
  soft_validate(:sv_contains_a_writer, set: :recommended_fields)
  soft_validate(:sv_has_title, set: :recommended_fields)
  soft_validate(:sv_has_some_type_of_year, set: :recommended_fields)
  soft_validate(:sv_is_article_missing_journal, set: :recommended_fields)
#  soft_validate(:sv_has_url, set: :recommended_fields) # probably should be sv_has_identifier instead of sv_has_url
  soft_validate(:sv_missing_required_bibtex_fields, set: :bibtex_fields)

#endregion

#region constants
# TW required fields (must have one of these fields filled in)
  TW_REQ_FIELDS = [
      :author,
      :editor,
      :booktitle,
      :title,
      :url,
      :journal,
      :year,
      :stated_year
  ] # either year or stated_year is acceptable
#endregion

 accepts_nested_attributes_for :notes

 #region ruby-bibtex related

  def to_bibtex # outputs BibTeX::Entry equivalent to me.
    b = BibTeX::Entry.new(type: self.bibtex_type)
    ::BIBTEX_FIELDS.each do |f|
      if !(f == :bibtex_type) && (!self[f].blank?)
        b[f] = self.send(f)
      end
    end
    if !self[:year_suffix].blank?
      b[:year] = self.year_with_suffix
    end
    # TODO add conversion of identifiers to ruby-bibtex fields, & notations to notes field.
    b
  end

  def valid_bibtex?
    self.to_bibtex.valid?
  end



  def self.new_from_bibtex(bibtex_entry)
# TODO On input, convert ruby-bibtex.url to an identifier & ruby-bibtex.note to a notation
    return false if !bibtex_entry.kind_of?(::BibTeX::Entry)
    s = Source::Bibtex.new(bibtex_type: bibtex_entry.type.to_s)
    bibtex_entry.fields.each do |key, value|
      v = value.to_s.strip
      s.send("#{key}=", v) # = v
    end
    s
  end

  # @return[String] A string that represents the year with suffix as seen in a BibTeX bibliography.
  #   returns "" if neither :year or :year_suffix are set.
  def year_with_suffix
    self[:year].to_s + self[:year_suffix].to_s
  end

  def create_related_people
    return false if !self.valid? ||
        self.new_record? ||
        (self.author.blank? && self.editor.blank?) ||
        self.roles.count > 0

    # if !self.valid
    #   errors.add(:base, 'invalid source')
    #   return false
    # end
    #
    # if self.new_record?
    #   errors.add(:base, 'unsaved source')
    #   return false
    # end
    #
    # if (self.author.blank? && self.editor.blank?)
    #   errors.add(:base, 'no people to create')
    #   return false
    # end
    #
    # if self.roles.count > 0
    #   errors.add(:base, 'this source already has people attached to it via roles')
    # end

    bibtex = to_bibtex
    bibtex.parse_names
    bibtex.names.each do |a|
      p         = Source::Bibtex.bibtex_author_to_person(a) #p is a TW person

      # TODO: These are required in present FactoryGirl tests, but not
      # in production, factor out when FactoryGirl + Housekeeping issues
      # are resolved.
      p.creator = self.creator
      p.updater = self.updater

      if bibtex.author
        self.authors << p if bibtex.author.include?(a)
      end
      if bibtex.editor
        self.editors << p if bibtex.editor.include?(a)
      end
    end
    return true

  end

  def self.bibtex_author_to_person(bibtex_author)
    return false if bibtex_author.class != BibTeX::Name
    Person.new(
        first_name: bibtex_author.first,
        prefix:     bibtex_author.prefix,
        last_name:  bibtex_author.last,
        suffix:     bibtex_author.suffix)
  end

#endregion  ruby-bibtex related

#region getters & setters
  def year=(value)
    if value.class == String
      value =~ /\A(\d\d\d\d)([a-zA-Z]*)\z/
      write_attribute(:year, $1.to_i) if $1
      write_attribute(:year_suffix, $2) if $2
      write_attribute(:year, value) if self.year.blank?
    else
      write_attribute(:year, value) 
    end
  end

  def month=(value)
    v = Utilities::Dates::SHORT_MONTH_FILTER[value]
    v = v.to_s if !v.nil?
    write_attribute(:month, v)
  end

  def note=(value)
    write_attribute(:note, value)
    self.notes.build({text: value + " [Created on import from BibTeX.]"} ) if self.new_record?
  end 

  def isbn=(value)
    write_attribute(:isbn, value)
    self.identifiers.build(type: 'Identifier::Guid::Isbn', identifier: value) 
  end

#TODO if language is set => set language_id
#endregion getters & setters

  def url_as_uri    # turn bibtex URL field into a Ruby URI object
      URI(self.url)  unless self.url.blank?
  end
  def url_valid?
    # this won't work in validation because validation methods don't allow "rescue"
    debugger
    return true if self.url.blank?
    case  URI.parse(self.url)
      when URI::BadURIError,  URI::InvalidURIError
        false
      else
        true
    end
  end




#region has_<attribute>? section
  def has_authors? # is there a bibtex author or author roles?
    return true if !(self.author.blank?)
    # author attribute is empty
    return false if self.new_record?
    # self exists in the db
    (self.authors.count > 0) ? (return true) : (return false)
  end

  def has_editors?
    return true if !(self.editor.blank?)
    # editor attribute is empty
    return false if self.new_record?
    # self exists in the db
    (self.editors.count > 0) ? (return true) : (return false)
  end

  def has_writer? # contains either an author or editor
    (has_authors?) || (has_editors?) ? true : false
  end

  def has_some_year? # is there a year or stated year?
    return true if !(self.year.blank?) || !(self.stated_year.blank?)
    false
  end

#endregion has_<attribute>? section

#region time/date related
  # @return[Time] returns nomenclature_date as stored in the db, if not computed yet, computes it.
  #   returns nil if there is no :year set. Does NOT set nomenclature_date in the object.
  def date
    return(self.nomenclature_date) if !(self.nomenclature_date.nil?)
    return(self.generate_nomenclature_date) if !(self.year.nil?)
    return(nil)
  end

  # @return[Boolean] sets the nomenclature_date within the object.
  def set_nomenclature_date
    self.nomenclature_date = self.generate_nomenclature_date
  end

  # TODO: Abstract to a Date/Time module
  # @return[Time] a UTC time (Uses Time instead of Date so that it can be saved as a UTC object -
  #   see http://www.ruby-doc.org/core-2.0.0/Time.html)
  #   returns nomenclature_date based on computation of the values of :year, :month, :day.
  #   Should only ever be called after validation!
  #    if :year is empty, return nil
  #    if :month is empty, returns 12/31/:year
  #    if :day is empty, returns the last day of the month
  def generate_nomenclature_date
    if self.year.nil?
      nil
    elsif self.month.nil?
      Time.utc(self.year, 12, 31)
    elsif self.day.nil?
      tmp = Time.utc(self.year, self.month)
      if tmp.month == 12 # want the last day of december
        Time.utc(self.year, 12, 31)
      else # time + 1 month - 1 day (60 sec * 60 min *24 hours)
        Time.utc(self.year, tmp.month + 1) - 86400
      end
    else
      Time.utc(self.year, self.month, self.day)
    end
  end

#endregion    time/date related

  protected

#region hard validations

# replaced with inclusion validation
#   def check_bibtex_type # must have a valid bibtex_type
#     errors.add(:bibtex_type, 'not a valid bibtex type') if !::VALID_BIBTEX_TYPES.include?(self.bibtex_type)
#   end

  def check_has_field # must have at least one of the required fields (TW_REQ_FIELDS)
    valid = false
    TW_REQ_FIELDS.each do |i| # for each i in the required fields list
      if !self[i].blank?
        valid = true
        break
      end
    end
    # if i is not nil and not == "", it's validly_published
    #if (!self[i].nil?) && (self[i] != '')
    #  return true
    #end
    errors.add(:base, 'no core data provided') if !valid
                      # return false # none of the required fields have a value
  end

=begin
  def day_valid? #make sure date is between 0-32
    return true if self.day.nil? # date not set
#    errors.add(:month, 'month is required if there is a day') if self.month.nil?
    errors.add(:day, 'the day can not be less than 1') if self.day <1
    errors.add(:day, 'invalid day for the month') if self.day > Time.utc(self.year, self.month).end_of_month.day
    #:message => "Subdomain %{value} is reserved."
  end

  def year_valid? #make sure year is a 4 digit year
    return true if self.year.nil? # year not set
    errors.add(:year, 'year must be greater than 999') if self.year < 1000
    errors.add(:year, 'year can be no more than 2 years in the future') if self.year > Time.now.year + 2
  end
=end

#endregion  hard validations

#region Soft_validation_methods
  def sv_has_authors
    if !(has_authors?)
      soft_validations.add(:author, 'There is no author associated with this source.')
    end
  end

  def sv_contains_a_writer # neither author nor editor
    if !has_writer?
      soft_validations.add(:author, 'There is neither an author,nor editor associated with this source.')
      soft_validations.add(:editor, 'There is neither an author,nor editor associated with this source.')
    end
  end

  def sv_has_title
    if (self.title.blank?)
      soft_validations.add(:title, 'There is no title associated with this source.')
    end
  end

  def sv_has_some_type_of_year
    if (!has_some_year?)
      soft_validations.add(:year, 'There is no year or stated year associated with this source.')
      soft_validations.add(:stated_year, 'There is no or stated year year associated with this source.')
    end
  end

  def sv_year_exists
    if (year.blank?)
      soft_validations.add(:year, 'There is no year associated with this source.')
    elsif year < 1700
      soft_validations.add(:year, 'This year is prior to the 1700s')
    end
  end

  def sv_missing_journal
    soft_validations.add(:bibtex_type, 'The source is missing a journal name.') if self.journal.blank?
  end

  def sv_is_article_missing_journal
    if (self.bibtex_type == 'article')
      if (self.journal.blank?)
        soft_validations.add(:bibtex_type, 'The article is missing a journal name.')
      end
    end
  end

  def sv_has_a_publisher
    if (self.publisher.blank?)
      soft_validations.add(:publisher, 'There is no publisher associated with this source.')
    end
  end

  def sv_has_booktitle
    if (self.booktitle.blank?)
      soft_validations.add(:booktitle, 'There is no book title associated with this source.')
    end
  end

  def sv_is_contained_has_chapter_or_pages
    if self.chapter.blank? && self.pages.blank?
      soft_validations.add(:chapter, 'There is neither a chapter nor pages with this source.')
      soft_validations.add(:pages, 'There is neither a chapter nor pages with this source.')
    end
  end

  def sv_has_school
    if (self.school.blank?)
      soft_validations.add(:school, 'There is no school associated with this thesis.')
    end
  end

  def sv_has_institution
    if (self.institution.blank?)
      soft_validations.add(:institution, 'There is not institution associated with this tech report.')
    end
  end

  # BETH:  I don't think we need these, let's discuss (Matt)
  # def sv_has_identifier
  #   #  TODO write linkage to identifiers (rather than local field save)
  #   # we have url, doi, isbn, & issn as bibtex fields, but they are also identifiers.
  #   # do need to make the linkages to identifiers as well as save in the local field?
  # end
  # 
  # def sv_has_url
  #   # TODO need to be converted to check for a URL identifier
  #   #if (self.url.blank?)
  #   #  soft_validations.add(:url, 'There is no URL associated with this source.')
  #   #end
  # end
  # 
  def sv_has_note
     # TODO we may need to check of a note in the TW sense as well - has_note? above.
     if (self.note.blank?)
       soft_validations.add(:note, 'There is no note associated with this source.')
     end
  end

  def sv_missing_required_bibtex_fields
    case self.bibtex_type
      when 'article' #:article       => [:author,:title,:journal,:year]
        sv_has_authors
        sv_has_title
        sv_is_article_missing_journal
        sv_year_exists
      when 'book' #:book          => [[:author,:editor],:title,:publisher,:year]
        sv_contains_a_writer
        sv_has_title
        sv_has_a_publisher
        sv_year_exists
      when 'booklet' #    :booklet       => [:title],
        sv_has_title
      when 'conference' #    :conference    => [:author,:title,:booktitle,:year],
        sv_has_authors
        sv_has_title
        sv_has_booktitle
        sv_year_exists
      when 'inbook' #    :inbook        => [[:author,:editor],:title,[:chapter,:pages],:publisher,:year],
        sv_contains_a_writer
        sv_has_title
        sv_is_contained_has_chapter_or_pages
        sv_has_a_publisher
        sv_year_exists
      when 'incollection' #    :incollection  => [:author,:title,:booktitle,:publisher,:year],
        sv_has_authors
        sv_has_title
        sv_has_booktitle
        sv_has_a_publisher
        sv_year_exists
      when 'inproceedings' #    :inproceedings => [:author,:title,:booktitle,:year],
        sv_has_authors
        sv_has_title
        sv_has_booktitle
        sv_year_exists
      when 'manual' #    :manual        => [:title],
        sv_has_title
      when 'mastersthesis' #    :mastersthesis => [:author,:title,:school,:year],
        sv_has_authors
        sv_has_title
        sv_has_school
        sv_year_exists
      #    :misc          => [],  (no required fields)
      when 'phdthesis' #    :phdthesis     => [:author,:title,:school,:year],
        sv_has_authors
        sv_has_title
        sv_has_school
        sv_year_exists
      when 'proceedings' #    :proceedings   => [:title,:year],
        sv_has_title
        sv_year_exists
      when 'techreport' #    :techreport    => [:author,:title,:institution,:year],
        sv_has_authors
        sv_has_title
        sv_has_institution
        sv_year_exists
      when 'unpublished' #    :unpublished   => [:author,:title,:note]
        sv_has_authors
        sv_has_title
        sv_has_note
    end
  end

#endregion   Soft_validation_methods

end

