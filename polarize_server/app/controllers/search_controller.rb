class SearchController < ApplicationController
	def index
		@query = params[:query]
        respond_to do |format|
            format.html
        end
    end
end
