
# A User is a TaxonWorks user, at present someone who can logon to the private workebench.
#
# All Data Models contain created_by_id and updated_by_id that references a User.
#
# A user may have a number of *attributes* that define roles/subclasses of a sort:
#
# 1) Administrators (User#is_administrator = true).  An administrator can do absolutely everything, in any
# project, and across any project, *except* set User#is_administrator = false.  It is intended that there
# be only 1-2 administrators per instance of TaxonWorks.
#
# 2) Project Administrators (ProjectMember#is_project_administrator).
# A project administrator can set Project settings and preferences, including the views that a Worker can see.
#
# 3) Superuser. A super_user (code only) is a User that is a profromct administrator OR administrator.
#
# 4) Worker. A worker is a User that can only see parts of the workbench allowed by a ProjectAdministrator.
#
# Data models in TaxonWorks reference People, who may have roles as Sources (or others), i.e. Users are not "data" and
# not linked directly to People records.
#
# Users must never be shared by real-life humans.
#
# @!attribute email
#   @return [String]
#     the users email, and login.
#
# @!attribute password_digest
#   @return [String]
#     the users password
#
# @!attribute remember_token
#   @return [String]
#   @todo
#
# @!attribute is_administrator
#   @return [Boolean]
#     true if user is an administrator, administrators can do *everything* in any project taxonworks
#
# @!attribute hub_favorites
#   @return [Hash]
#    per project favorites named from items in user_tasks.yml or hub_data.yml
#    format is
#    { project_id: {data: [ 'ModelName' ], tasks: [ :task_index_name ] }, ... }
#
# @!attribute password_reset_token
#   @return [String]
#     if user has requested a password reset the token is stored here 
#
# @!attribute password_reset_token_date
#   @return [DateTime]
#     helps determine how long the password reset token is valid 
#
# @!attribute name
#   @return [String]
#   a users name: Not intended to be a nickname, but this is loosely enforced. Attribute is intended to identify a human who owns this account.
#
# @!attribute current_sign_in_at
#   @return [ActiveSupport::TimeWithZone]
#     time of current sign in
#
# @!attribute last_sign_in_at
#   @return [ActiveSupport::TimeWithZone]
#    time of sign in prior to this sign in
#
# @!attribute last_sign_in_ip
#   @return [String]
#    IP address of the machine user used to log in from prior to this current log in
#
# @!attribute current_sign_in_ip
#   @return [String]
#    IP address of the machine user is currently logged in from
#
# @!attribute hub_tab_order
#   @return [Array]
#     tabs, referenced as Strings, defining the users preference for their order
#
# @!attribute api_access_token
#   @return [String]
#    authentication token used to authenticate against /api endpoints
#
# @!attribute is_flagged_for_password_reset
#   @return [Boolean]
#     when true user must reset their password before doing anything further
#
# @!attribute footprints
#   @return [Hash]
#     tracks the users recent requests
#
# @!attribute sign_in_count
#   @return [Integer]
#     a count of the number of times a user has logged in
#
# @!attribute self_created [r]
#   @return [true, false]
#   Only used for when .new_record? is true. If true assigns creator and updater as self.
#
#
class User < ApplicationRecord
  include Shared::Identifiers # TODO: this is required before Housekeeping::Users, resolve

  include Shared::DataAttributes
  include Shared::Notes
  include Shared::Tags

  include Housekeeping::Users
  include Housekeeping::Timestamps
  include Housekeeping::AssociationHelpers

  include Shared::RandomTokenFields[:password_reset]
  has_secure_password

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  store :preferences, accessors: [:disable_chime], coder: JSON

  attr_accessor :set_new_api_access_token
  attr_accessor :self_created

  before_validation { self.email = email.to_s.downcase }

  before_save :generate_api_access_token, if: :set_new_api_access_token
  # @todo downcase does not work for non-ascii characters which means our validation for uniqueness will fail ... why?
  # @see http://stackoverflow.com/questions/2049502/what-characters-are-allowed-in-email-address
  # @see http://unicode-utils.rubyforge.org/
  before_save { self.email = email.to_s.downcase }

  after_save :configure_self_created, if: :self_created

  before_create :set_remember_token
  before_create { self.hub_tab_order = DEFAULT_HUB_TAB_ORDER }

  validates :email, presence: true,
    format:  {with: VALID_EMAIL_REGEX},
    uniqueness: true

  validates :password,
    length: {minimum: 8, if: :validate_password?},
    confirmation: {if: :validate_password?}

  validates :name, presence: true
  validates :name, length: {minimum: 2}, unless: -> { self.name.blank? }

  has_many :project_members, dependent: :destroy
  has_many :projects, through: :project_members
  has_many :pinboard_items, dependent: :destroy

  scope :is_administrator, -> { where(is_administrator: true) }

  # @return [Scope] of projects
  def administered_projects
    projects.where(id: project_members.where(is_project_administrator: true).pluck(:project_id))
  end

  # @return [Boolean]
  def administers_projects?
    administered_projects.any?
  end

  # TODO: Deprecate for a `lib/query/user/filter`  
  # @param [String, User, Integer] user
  # @return [Integer] selected user id
  def self.get_user_id(user)
    # no way to know who the current user is, so can't pre-set user_id
    case user.class.name
      when 'String'
        # search by name or email
        ut     = User.arel_table
        c1     = ut[:name].eq(user).or(ut[:email].eq(user.downcase)).to_sql
        t_user = User.where(c1).first
        if t_user.present?
          user_id = t_user.id
        else  # try to convert to a number, to see if it came directly from a web page
          t_user = user.to_i
          if t_user > 0
            t_user = User.find(t_user).try(:id)
          else
            t_user = nil
          end
          user_id = t_user
        end
      when 'User'
        user_id = user.id
      when 'Integer'
        user_id = user
    end
    user_id
  end

  # @param [String, User, Integer, Array] users
  # @return [Array of Integers] selected user ids
  def self.get_user_ids(*users)
    user_ids = []
    users.flatten.each { |user|
      case user.class.name
        when 'String'
          # search by name or email
          ut = User.arel_table
          c1 = ut[:name].eq(user)
                 .or(ut[:name].matches("%#{user}"))
                 .or(ut[:name].matches("%#{user}%"))
                 .or(ut[:email].eq(user))
                 .or(ut[:email].matches("%#{user}"))
                 .or(ut[:email].matches("%#{user}%")).to_sql
          user_ids.push(User.where(c1).pluck(:id))
        when 'User'
          user_ids.push(user.id)
        when 'Integer'
          user_ids.push(user)
      end
    }
    user_ids.flatten.uniq
  end

  # @param [Integer] project_id
  # @return [Scope] of users
  def self.not_in_project(project_id)
    ids = ProjectMember.where(project_id: project_id).pluck(:user_id)
    return where(false) if ids.empty?

    User.where(User.arel_table[:id].not_eq_all(ids))
  end

  # @param [Integer] project_id
  # @return [Scope] of ids for users in the project
  # TODO: get rid of $project_id
  def self.in_project(project_id = $project_id)
    ProjectMember.where(project_id: project_id).distinct.pluck(:user_id)
  end

  # @return [String] of token
  def User.secure_random_token
    SecureRandom.urlsafe_base64
  end

  # @param [String] token
  # @return [String]
  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  # @param [Project] project
  # @return [Boolean] true if user is_administrator or is_project_administrator
  def is_superuser?(project = nil)
    is_administrator || is_project_administrator?(project)
  end

  # @return [Boolean] true if is_administrator = true
  def is_administrator?
    is_administrator.blank? ? false : true
  end

  # @param [Project] project
  # @return [Boolean] true if user is_project_administrator for the project passed
  def is_project_administrator?(project = nil)
    return false if project.nil?
    project.project_members.where(user_id: id).first.is_project_administrator
  end

  # @param [Project, Integer]
  # @return [Boolean]
  def member_of?(project)
    ProjectMember.where(project_id: project, user_id: self.id).any?
  end

  # @return [Hash]
  def hub_favorites
    read_attribute(:hub_favorites) || {}
  end

  # @param [Boolean] state
  # @return [Ignored]
  def able_chime(state)
    preferences[:disable_chime] = (not state)
  end

  # @return [Ignored]
  def enable_chime
    able_chime(false)
  end

  # @return [Ignored]
  def disable_chime
    able_chime(true)
  end

  # @return [Boolean]
  def chime_enabled?
    preferences[:disable_chime]
  end

  
  # TODO: move to User concern
  # rubocop:disable Style/StringHashKeys
  # @param [Hash] options
  # @return [Boolean] always true
  def add_page_to_favorites(options = {}) # name: nil, kind: nil, project_id: nil
    validate_favorite_options(options)
    n = options[:name]
    p = options[:project_id].to_s
    k = options[:kind]
    u = hub_favorites.clone

    u[p]    = {'data' => [], 'tasks' => []} if !u[p]
    u[p][k] = u[p][k].push(n).uniq[0..19].sort

    update_column(:hub_favorites, u)
    true
  end
  # rubocop:enable Style/StringHashKeys

  
  # TODO: move to User concern
  # @param [Hash] options
  def remove_page_from_favorites(options = {}) # name: nil, kind: nil, project_id: nil
    validate_favorite_options(options)
    new_routes = hub_favorites.clone
    new_routes[options['project_id'].to_s][options['kind']].delete(options['name'])
    update_column(:hub_favorites, new_routes)
  end

  # TODO: move to User concern
  # @param [Hash] options
  # @return [Boolean]
  def validate_favorite_options(options)
    return false if !options.select { |k, v| k.nil? || v.nil? }.empty?
    return false if !member_of?(options['project_id'])
    true
  end

  # TODO: move to User concern
  # @return [Boolean]
  #   If user has been active within the last 5 minutes, and at least 5
  #   seconds past their last activity, update their time_active.
  #   The latter prevents multiple writes on many async calls.
  def update_last_seen_at
    if !last_seen_at.nil?
      t = Time.now - last_seen_at
      if t > 5
        a = t < 301 ? time_active + t : (time_active || 0)
        update_columns(last_seen_at: Time.now, time_active: a) if t > 5
      end
    end
  end


  # TODO: move to User concern
  # @param [String] recent_route
  # @param [Object] recent_object
  # @return [Boolean] always true
  def add_recently_visited_to_footprint(recent_route, recent_object = nil)
    case recent_route
      when /\A\/\Z/ # the root path '/'
      when /\A\/hub/ # any path which starts with '/hub'
      when /\/autocomplete\?/ # any path used for AJAX autocomplete
      else

        fp                     = footprints.dup
        fp['recently_visited'] ||= []

        attrs = {recent_route => {}}
        if !recent_object.nil?
          attrs[recent_route].merge!(object_type: recent_object.class.to_s, object_id: recent_object.id)
        end

        fp['recently_visited'].unshift(attrs)
        fp['recently_visited'] = fp['recently_visited'].uniq { |a| a.keys }[0..19]

        self.footprints_will_change! # if this isn't thrown weird caching happens !
        self.update_column(:footprints, fp)
    end

    true
  end

  # TODO:  This needs to show cross-project pinboard items as well
  # @param [Integer] project_id
  # @return [Scope] of pinboard items
  def pinboard_hash(project_id)
    pinboard_items.where(project_id: project_id).order('pinned_object_type DESC, position').to_a.group_by { |a| a.pinned_object_type }
  end

  # @param [String] klass
  # @return [Integer] the total records of this klass created by this user
  def total_objects(klass) # klass_name is a string, need .constantize in next line
    klass.where(creator: self).count
  end

  # @param [String] klass_string
  # @return [Integer]
  def total_objects2(klass_string)
    self.send("created_#{klass_string}").count #klass.where(creator:self).count
  end

  # rubocop:disable Metrics/MethodLength
  # @return [Hash]
  # @user.get_class_created_updated # => { "projects" => {created: 10, first_created: datetime, updated: 10, last_updated: datetime} }
  def get_class_created_updated
    Rails.application.eager_load! if Rails.env.development?
    data = {}

    User.reflect_on_all_associations(:has_many).each do |r|
      key = nil
      puts r.name.to_s
      if r.name.to_s =~ /created_/
        # puts "after created"
        key = :created
      elsif r.name.to_s =~ /updated_/
        # puts "after updated"
        key = :updated
      end

      if key
        n     = r.klass.name.underscore.humanize.pluralize
        count = self.send(r.name).count

        if data[n]
          data[n][key] = count
        else
          data[n] = {key => count}
        end

        if count == 0
          data[n][:first_created] = 'n/a'
          data[n][:last_updated]  = 'n/a'
        else
          data[n][:first_created] = self.send(r.name).limit(1).order(created_at: :asc).first.created_at
          data[n][:last_updated]  = self.send(r.name).limit(1).order(updated_at: :desc).first.updated_at
        end
      end
    end
    data
  end
  # rubocop:enable Metrics/MethodLength

  # @return [String]
  def generate_api_access_token
    self.api_access_token = Utilities::RandomToken.generate
  end

  # @return [Boolean] always true
  def require_password_presence
    @require_password_presence = true
  end

  private

  # @return [String]
  def set_remember_token
    self.remember_token = User.encrypt(User.secure_random_token)
  end

  # @return [Boolean]
  def validate_password?
    password.present? || password_confirmation.present? || @require_password_presence
  end

  def configure_self_created
    if !self.new_record? && self.creator.nil? && self.updater.nil?
      self.update_columns(created_by_id: self.id, updated_by_id: self.id) # !?
    end
  end
end
