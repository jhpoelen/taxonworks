class TaxonNamesController < ApplicationController
  include DataControllerConfiguration::ProjectDataControllerConfiguration

  before_action :set_taxon_name, only: [:show, :edit, :update, :destroy, :browse, :original_combination]

  # GET /taxon_names
  # GET /taxon_names.json
  def index
    @recent_objects = TaxonName.recent_from_project_id(sessions_current_project_id).order(updated_at: :desc).limit(10)
    render '/shared/data/all/index'
  end

  # GET /taxon_names/1
  # GET /taxon_names/1.json
  def show
  end

  # GET /taxon_names/new
  def new
    @taxon_name = Protonym.new(source: Source.new)
  end

  # GET /taxon_names/1/edit
  def edit
    @taxon_name.source = Source.new if !@taxon_name.source
  end

  # GET /taxon_names/select_options
  def select_options
    @taxon_names = TaxonName.select_optimized(sessions_current_user_id, sessions_current_project_id)
  end

  # POST /taxon_names
  # POST /taxon_names.json
  def create
    @taxon_name = TaxonName.new(taxon_name_params)
    respond_to do |format|
      if @taxon_name.save
        format.html { redirect_to url_for(@taxon_name.metamorphosize),
                      notice: "Taxon name '#{@taxon_name.name}' was successfully created." }
        format.json { render :show, status: :created, location: @taxon_name.metamorphosize }
      else
        format.html { render action: :new }
        format.json { render json: @taxon_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /taxon_names/1
  # PATCH/PUT /taxon_names/1.json
  def update
    respond_to do |format|
      if @taxon_name.update(taxon_name_params)
        @taxon_name.reload
        format.html { redirect_to url_for(@taxon_name.metamorphosize), notice: 'Taxon name was successfully updated.' }
        format.json { render :show, status: :ok, location: @taxon_name.metamorphosize }
      else
        format.html { render action: :edit }
        format.json { render json: @taxon_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /taxon_names/1
  # DELETE /taxon_names/1.json
  def destroy
    @taxon_name.destroy
    respond_to do |format|
      format.html { redirect_to taxon_names_url }
      format.json { head :no_content }
    end
  end

  def search
    if params[:id].blank?
      redirect_to taxon_names_path, notice: 'You must select an item from the list with a click or tab press before clicking show.'
    else
      redirect_to taxon_name_path(params[:id])
    end
  end

  def autocomplete
    render json: {} and return if params[:term].blank?
    @taxon_names = Queries::TaxonName::Autocomplete.new(
      params[:term],
      autocomplete_params.to_h
    ).autocomplete
  end

  def list
    @taxon_names = TaxonName.with_project_id(sessions_current_project_id).order(:id).page(params[:page])
  end

  # GET /taxon_names/download
  def download
    send_data Download.generate_csv(
      TaxonName.where(project_id: sessions_current_project_id)
    ), type: 'text', filename: "taxon_names_#{DateTime.now}.csv"
  end

  def batch_load
  end

  def ranks
    render json: RANKS_JSON.to_json
  end

  def preview_simple_batch_load
    if params[:file]
      @result =  BatchLoad::Import::TaxonifiToTaxonworks.new(batch_params)
      digest_cookie(params[:file].tempfile, :simple_taxon_names_md5)
      render 'taxon_names/batch_load/simple/preview'
    else
      flash[:notice] = 'No file provided!'
      redirect_to action: :batch_load
    end
  end

  def create_simple_batch_load
    if params[:file] && digested_cookie_exists?(params[:file].tempfile, :simple_taxon_names_md5)
      @result =  BatchLoad::Import::TaxonifiToTaxonworks.new(batch_params)
      if @result.create
        flash[:notice] = "Successfully proccessed file, #{@result.total_records_created} taxon names were created."
        render 'taxon_names/batch_load/simple/create' and return
      else
        flash[:alert] = 'Batch import failed.'
      end
    else
      flash[:alert] = 'File to batch upload must be supplied.'
    end
    render :batch_load
  end

  def preview_castor_batch_load
    if params[:file]
      @result = BatchLoad::Import::TaxonNames::CastorInterpreter.new(batch_params)
      digest_cookie(params[:file].tempfile, :Castor_taxon_names_md5)
      render 'taxon_names/batch_load/castor/preview'
    else
      flash[:notice] = 'No file provided!'
      redirect_to action: :batch_load
    end
  end

  def create_castor_batch_load
    if params[:file] && digested_cookie_exists?(params[:file].tempfile, :Castor_taxon_names_md5)
      @result = BatchLoad::Import::TaxonNames::CastorInterpreter.new(batch_params)
      if @result.create
        flash[:notice] = "Successfully proccessed file, #{@result.total_records_created} items were created."
        render 'taxon_names/batch_load/castor/create' and return
      else
        flash[:alert] = 'Batch import failed.'
      end
    else
      flash[:alert] = 'File to batch upload must be supplied.'
    end
    render :batch_load
  end

  def browse
    @data = NomenclatureCatalog.data_for(@taxon_name)
  end

  def parse
    @result = TaxonWorks::Vendor::Biodiversity::Result.new(
      query_string: params.require(:query_string),
      project_id: sessions_current_project_id
    ).result
  end

  private

  def set_taxon_name
    @taxon_name = TaxonName.with_project_id(sessions_current_project_id).includes(:creator, :updater).find(params[:id])
    @recent_object = @taxon_name
  end

  def autocomplete_params
    params.permit(:valid, :exact, type: [], parent_id: [], nomenclature_group: []).to_h.symbolize_keys.merge(project_id: sessions_current_project_id)
  end

  def taxon_name_params
    params.require(:taxon_name).permit(
      :name,
      :parent_id,
      :year_of_publication,
      :etymology,
      :verbatim_author, :rank_class, :type, :masculine_name,
      :feminine_name, :neuter_name, :also_create_otu,
      roles_attributes: [
        :id, :_destroy, :type, :person_id, :position,
        person_attributes: [
          :last_name, :first_name, :suffix, :prefix
        ]
      ],
      origin_citation_attributes: [:id, :_destroy, :source_id, :pages]
    )
  end

  def batch_params
    params.permit(
      :file,
      :parent_taxon_name_id,
      :nomenclature_code,
      :also_create_otu,
      :import_level).merge(
        user_id: sessions_current_user_id,
        project_id: sessions_current_project_id
      ).to_h.symbolize_keys
  end
end

require_dependency Rails.root.to_s + '/lib/batch_load/import/taxon_names/castor_interpreter.rb'
