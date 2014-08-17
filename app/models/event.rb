class Event < ActiveRecord::Base
	belongs_to :partner
	has_many :users, through: :excursions
	has_many :excursions, dependent: :destroy 
	has_many :conversations, dependent: :destroy
	mount_uploader :image, ImageUploader

	validates :title, presence: true
	validates :location, presence: true
	validates :start_time, presence: true

	attr_accessible :title, :description, :location, :start_time, :end_time, :image, :attended, :partner_id, :quantity, :remote_image_url, :closed, :music, :discussion, :activity, :party, :show, :food, :games, :twenty_one, :paid, :event_type, :messages_count

	def self.assign_and_return_new params
		total_params = params[:event]
		tags = params[:tags].downcase.split(',').map do |t|
			{t.to_sym => true}
		end.inject Hash.new, :merge
		total_params = total_params.merge tags
		total_params = total_params.merge({twenty_one: true}) if params[:requirements].include? "21+"
		total_params = total_params.merge({paid: true}) if params[:requirements].include? "Paid"
		Event.new total_params
	end

	def conversation
		conversations.first
	end



	def self.update_message_counts
		all.each do |event|
			next if !event.conversations.first
			count = event.conversations.first.messages.count
		end
	end


	def creator
		excursions.where(created: true)[0].user if excursions.where(created: true)[0]
	end

	def time user
		# if start_time - Time.now < 24.hours
		# 	tzone.time(start_time).strftime("%m/%d/%g at %I:%M%p")
		# else
		# 	tzone.time(start_time).strftime("%m/%d/%g at %I:%M%p") 
		# end
		if start_time - Time.now < 24.hours && start_time.beginning_of_day.day == user.user_time.beginning_of_day.day
			stime = (start_time).strftime("Today at %I:%M%p")
		else
			stime = (start_time).strftime("%m/%d/%g at %I:%M%p") 
		end
	end

	def attendees
		excursions.where(accepted: true)
	end

	def accepted?
		excursions.where(accepted: false).empty?
	end

	def passed_by? user
		!Excursion.where(user_id: user.id, event_id: id, passed: true ).empty?
	end

	def untouched_by? user
		Excursion.where(user_id: user.id, event_id: id).empty?
	end

	def people_count
		excursions.where(accepted: true).count
	end

	def short_location
		location.length > 24 ? location[0..23] + ".." : location
	end

	def self.open user
		where('start_time > (?)', (user.user_time - 6.hours) ).order(:start_time).select { |event| !event.passed_by?(user) }
	end

	def self.hosted_by user
		invite_excursions = user.excursions.where(created: true)
		invite_excursions.map(&:event).compact.select { |event| event.start_time > (user.user_time - 6.hours) }.sort_by(&:start_time)
	end

	def self.past user
		user.excursions.where(accepted: true).map(&:event).select { |event| event.start_time < (user.user_time - 6.hours) }.sort_by(&:start_time).reverse
	end

	def self.joined_by user
		user.excursions.where(accepted: true).map(&:event).select { |event| event.start_time > (user.user_time - 6.hours) }.sort_by(&:start_time)
	end 

	def joined_by user
		!excursions.where(accepted: true, user_id: user.id).empty?
	end

end