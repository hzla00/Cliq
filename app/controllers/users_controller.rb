class UsersController < ApplicationController
	before_filter :get_user

	def show
		@category = Category.where(name: "Do").first
		@format = Category.self_format
		@formatted_interests = current_user.formatted_interests
		respond_to do |format|
  		format.html 
  		format.json { render :json => @user }
		end
	end

	def other
		@user = User.find params[:id]
		@format = Category.other_format @user.first_name
		@formatted_interests = @user.formatted_interests
		render layout: false
	end

	def send_activation
		UserMailer.welcome_email(current_user, params[:email]).deliver
		render nothing: true
	end

	def activate
		session[:user_id] = params[:id]
		if params[:code] == @user.activation
			session[:user_id] = @user.id
			@user.activate
			@message = "You have been activated"
			redirect_to search_path and return
		else
			@message = "Activation Failed"
			redirect_to search_path
		end
	end

	def search
		@results = nil
	end

	def main
		@results = nil
	end

	def search_results #add support for searching location without ids
		if params[:ids] == ""
			results = current_user.search_similar current_user.activities
			render partial: "search_results", locals: {results: results}
			return
		end
		if params[:location_id] != "" && params[:location] != ""
			location = Location.find params[:location_id]
		elsif params[:location] != ""
			cords = Geocoder.coordinates params[:location]
			if cords
				location = Location.create name: params[:location], latitude: cords[0], longitude: cords[1]
			else
				location = "invalid"
			end
		else
			location = nil
		end
		results = current_user.search_similar(Activity.parse_interests(params[:ids]), location)
		if params[:type] == "swipe"
			render partial: "swipe_results", locals: {results: results}
			return
		end
		render partial: "search_results", locals: {results: results}
	end

private
	
	def get_user
		@user = params[:user_id] ? User.find(params[:user_id]) : User.find(params[:id]) if params[:id]
	end

end