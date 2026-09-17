class NanasController < ApplicationController
  before_action :set_nana, only: %i[ show edit update destroy ]

  # GET /nanas or /nanas.json
  def index
    @nanas = Nana.all
  end

  # GET /nanas/1 or /nanas/1.json
  def show
  end

  # GET /nanas/new
  def new
    @nana = Nana.new
  end

  # GET /nanas/1/edit
  def edit
  end

 def create
  @nana = Nana.new(nana_params)

  if @nana.save
    # 作成完了後、show画面ではなく直接トーク画面へリダイレクト
    redirect_to "/ai?nana_id=#{@nana.id}"
  else
    render :new, status: :unprocessable_entity
  end
end

  # PATCH/PUT /nanas/1 or /nanas/1.json
  def update
    respond_to do |format|
      if @nana.update(nana_params)
        format.html { redirect_to @nana, notice: "Nana was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @nana }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @nana.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /nanas/1 or /nanas/1.json
  def destroy
    @nana.destroy!

    respond_to do |format|
      format.html { redirect_to nanas_path, notice: "Nana was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nana
      @nana = Nana.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def nana_params
      params.require(:nana).permit(:name, :profile_image)
    end
end
