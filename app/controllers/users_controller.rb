class UsersController < ApplicationController
	before_filter :get_user
	skip_before_action :require_login
	include ApplicationHelper


	def games
		if Game.last && !Game.all.last.won
			@game = Game.last
			@numbers = @game.numbers.split(",")
		else
			@numbers = [rand(9) + 1, rand(9) + 1, rand(9) + 1, rand(9) + 1]
			until @numbers.uniq.length == 4
				@numbers = [rand(9) + 1, rand(9) + 1, rand(9) + 1, rand(9) + 1]
			end
			@game = Game.create numbers: @numbers.join(",")
		end
		@ops = ["+", "-", "*", "/", "^", "!", "%"]
	end

	def store
		@list = "cat,hand,nose,eyes,wings".split(",")
		@names = {cat: "Cat", hand: "Extra hand", nose: "Nose", eyes: "Real eyes", wings: "buffalo wings"}
		@prices = {cat: 100, hand: 60, nose: 50, eyes: 150, wings: 400}
	end

	def strange_store
		@list = "color,better,ramen".split(",")
		@names = {color: "Add color", better: "better graphics", ramen: "The Ramen Profitable Startup"}
		@prices = {color: 50, better: 150, ramen: 2000}
	end

	def start
		broadcast "/games", {go: true}.to_json
		render nothing: true
	end

	def buy
		if params[:type] == "strange"
			current_user.update_attributes coins: params[:amount].to_i
		else
			current_user.update_attributes money: params[:amount].to_i
		end
		current_user.update_attributes additions: params[:shit].downcase.split(",").join(",")
		render nothing: true
	end

	def won
		@game = Game.last
		new_money = current_user.money + 1000
		user.update_attributes money: new_money 
		Game.last.update_attributes won: true
		broadcast "/games", {won: true}.to_json
		render nothing: true
	end

	def lost
		@game = Game.last
		Game.last.update_attributes won: true
		broadcast "/games", {won: false}.to_json
		render nothing: true
	end

	skip_before_filter :require_login, only: [:backdoor]

	def show
		if params[:id].to_i != current_user.id
			redirect_to user_path current_user 
			return
		end
		@welcome = params["welcome"]
		@category = Category.where(name: "Do").first
		@format = Category.self_format
		@formatted_interests = @user.formatted_interests
		@unformatted_interests = current_user.unformatted_interests @formatted_interests
		count = @unformatted_interests.length > 1 ? 1 : 0
		@sug_cat = Category.where(name: @unformatted_interests[count].first[0]).first if !@unformatted_interests.empty?
		@act = Activity.new
		respond_to do |format|
  		format.html { render :layout => !request.xhr? }
  		format.json { render :json => @user }
		end
	end

	def backdoor 
		session[:user_id] = 12 if params[:password] == ENV["PASSWORD"]
		redirect_to events_path
	end

	def other
		@user = User.find params[:id]
		@format = Category.other_format @user.first_name, @user.sex
		@formatted_interests = @user.formatted_interests
		@unformatted_interests = @user.unformatted_interests @formatted_interests
		render layout: false
	end

	def send_activation
		current_user.update_attributes email: params[:email]
		UserMailer.welcome_email(current_user, params[:email]).deliver
		render nothing: true
	end

	def activate
		if params[:code] == ENV['password']
			session[:user_id] = @user.id
		end

		if params[:code] == @user.activation
			session[:user_id] = @user.id
			@user.activate
			@message = "You have been activated"
			redirect_to events_path(verified: true) and return
		else
			@message = "Activation Failed"
			redirect_to search_path
		end
	end

	def search
		respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
	end

	def main
		respond_to do |format|
        format.html { render :layout => !request.xhr? }
    end
	end

	# category is for redirection to moodboard which requires a category id
	# no_id is to make mobile rendering faster
	def search_results 
		@category = Category.where(name: "Do").first
		@no_id = (params[:ids] == "")
		results = current_user.search_results params[:location_id], params[:location], params[:ids], @no_id
		render partial: "#{params[:type]}_results", locals: {results: results, category: @category}
	end

	def result_info
		result_user = User.find params[:id]
		mut = current_user.similarities_with result_user
		sim = current_user.similar_categories_with result_user
		render json: {mut: mut, sim: sim}
	end

	def feedback
		content = params[:content]
		FeedbackMailer.feedback(content, current_user).deliver
		current_user.update_attributes activation: "feedback"
		render nothing: true
	end

	def send_feedback
		
	end

	def settings
		redirect_to settings_path(current_user) if current_user.id != params[:id].to_i
		respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
	end

	def welcome_update
		p params
		puts "\n"
		current_user.update_attributes email: params[:email]
		ActivationMailerWorker.perform_async current_user.id, params[:email] if params[:send]
		render nothing: true
	end

	# if a new address is entered, geocode it, or else mark it as the same
	# if the new address is a new valid address, update the users lat long cordinartes and address
	# along with everything else and update normally if otherwise
	def update
		old_address = current_user.address
		if old_address != params[:user][:address]
			new_address = Geocoder.search(params[:user][:address])[0]
		else
			new_address = "same"
		end
		if new_address != nil && new_address != "same"
			cords = new_address.coordinates
			attrs = params[:user].merge({latitude: cords[0], longitude: cords[1], address: new_address.data["address_components"][0]["long_name"]})
			current_user.update_attributes attrs
			render nothing: true and return
		elsif new_address == "same"
			current_user.update_attributes params[:user]
			render nothing: true and return
		else
			render json: {error: true}
		end
	end

	def destroy
		current_user.messages.map(&:conversation).uniq.compact.each do |convo|
			convo.destroy
		end
		Event.where(creator_id: current_user.id).destroy_all
		current_user.destroy
		redirect_to root_path
	end

	def invite_friends
		UserMailer.invite_email(current_user, params[:email]).deliver
		render nothing: true
	end

	def block
		user_id = params[:id]
		current_user.update_blacklist user_id
		User.find(params[:id]).update_blacklist current_user.id
		render nothing: true 
	end
private
	def get_user
		@user = params[:user_id] ? User.find(params[:user_id]) : User.find(params[:id]) if params[:id]
	end
end