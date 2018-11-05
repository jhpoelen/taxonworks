# A Topic is a user defined subject.  It is used in conjuction with a citation on an OTU.  
# Topics assert that "this source says something about this taxon on this topic."
#
class Topic < ControlledVocabularyTerm

  # TODO: Why?!
  include Shared::Tags

  has_many :citation_topics, inverse_of: :topic, dependent: :destroy
  has_many :citations, through: :citation_topics, inverse_of: :topics

  has_many :contents, inverse_of: :topic, dependent: :destroy
  has_many :otus, through: :contents
  has_many :otu_page_layout_sections, -> { where(otu_page_layout_sections:
                                                 {type: 'OtuPageLayoutSection::StandardSection'}) },
  inverse_of: :topic
  has_many :otu_page_layouts, through: :otu_page_layout_sections

  scope :used_on_klass, -> (klass) { joins(:citations).where(citations: {citation_object_type: klass}) }

  # TODO: Deprecate for CVT + params (if not already done)
  def self.find_for_autocomplete(params)
    term = "#{params[:term]}%"
    where_string = "name LIKE '#{term}' OR name ILIKE '%#{term}' OR name = '#{term}' OR definition ILIKE '%#{term}'"
    ControlledVocabularyTerm.where(where_string).where(project_id: params[:project_id], type: 'Topic')
  end

  # @param used_on [String] one of `Citation` (default) or `Content`
  # @return [Scope]
  #    the max 10 most recently used topics, as used on Content or Citation
  def self.used_recently(used_on = 'Citation')
    t = case used_on
          when 'Citation'
            CitationTopic.arel_table
          when 'Content'
            Content.arel_table
        end

    p = Topic.arel_table

    # i is a select manager
    i = t.project(t['topic_id'], t['created_at']).from(t)
          .where(t['created_at'].gt(1.weeks.ago))
          .order(t['created_at'])

    # z is a table alias
    z = i.as('recent_t')

    Topic.joins(
      Arel::Nodes::InnerJoin.new(z, Arel::Nodes::On.new(z['topic_id'].eq(p['id'])))
    ).distinct.limit(10)
  end

  # @params klass [String] if target is `Citation` then if provided limits to those classes with citations,
  # if `Content` then not used
  # @params target [String] one of `Citation` or `Content`
  # @return [Hash] topics optimized for user selection
  def self.select_optimized(user_id, project_id, klass, target = 'Citation')
    h = {
      quick: [],
      pinboard: Topic.pinned_by(user_id).where(project_id: project_id).to_a
    }

    case target
      when 'Citation'
        h[:recent] = Topic.where(project_id: project_id)
                       .used_on_klass(klass).used_recently('Citation').limit(10).distinct.to_a
      when 'Content'
        h[:recent] = Topic.joins(:contents)
                       .where(project_id: project_id).used_recently('Content').limit(10).distinct.to_a
    end

    h[:quick] = (Topic.pinned_by(user_id)
                   .pinboard_inserted.where(project_id: project_id).to_a + h[:recent][0..3]).uniq
    h
  end

end
