module Admin
  class RaceDeadlinesController < ApplicationController
    before_action :require_admin
    before_action :set_race_deadline, only: %i[show edit update destroy]

    # GET /race_deadlines
    # GET /race_deadlines.json
    def index
      @race_deadlines = RaceDeadline.all
    end

    # GET /race_deadlines/1
    # GET /race_deadlines/1.json
    def show
    end

    # GET /race_deadlines/new
    def new
      @race_deadline = RaceDeadline.new(start_date: 1.week.ago.to_date, due_date: 1.week.from_now.to_date)
    end

    # GET /race_deadlines/1/edit
    def edit
    end

    # POST /race_deadlines
    # POST /race_deadlines.json
    def create
      @race_deadline = RaceDeadline.new(race_deadline_params)

      respond_to do |format|
        if @race_deadline.save
          format.html { redirect_to admin_race_deadlines_path, notice: 'Race deadline was successfully created.' }
          format.json { render :show, status: :created, location: @race_deadline }
        else
          format.html { render :new }
          format.json { render json: @race_deadline.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /race_deadlines/1
    # PATCH/PUT /race_deadlines/1.json
    def update
      respond_to do |format|
        if @race_deadline.update(race_deadline_params)
          format.html { redirect_to admin_race_deadlines_path, notice: 'Race deadline was successfully updated.' }
          format.json { render :show, status: :ok, location: @race_deadline }
        else
          format.html { render :edit }
          format.json { render json: @race_deadline.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /race_deadlines/1
    # DELETE /race_deadlines/1.json
    def destroy
      @race_deadline.destroy
      respond_to do |format|
        format.html { redirect_to admin_race_deadlines_url, notice: 'Race deadline was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    def set_race_deadline
      @race_deadline = RaceDeadline.find(params[:id])
    end

    def race_deadline_params
      params.require(:race_deadline).permit(:race_type, :due_date, :start_date, :description, :active)
    end
  end
end
