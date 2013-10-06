class AlchemyController < ApplicationController
    def alchemy_api
        respond_to do |format|
            format.html
        end
    end

    def show
        respond_to do |format|
            format.html
        end
    end

    def index
        respond_to do |format|
            format.html
        end
    end

    def alchemy_api_ajax
        respond_to do |format|
            result = {1 => 2}
            format.json {render :json => result.to_json}
        end
    end
end
