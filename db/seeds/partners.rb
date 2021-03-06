# puts "loading partners"

# Partner.create name: "Burger & Beer Joint", type: "food", location: "11662 University Blvd., Orlando FL 32817", mon: "11:30am - 12am", tues: "11:30am - 12am", wed: "11:30am - 12am", thurs: "11:30am - 12am", fri: "11:30am - 2am", sat: "11:30am - 2am", sun: "11:30am - 12am"
# Partner.create name: "Dungeon Lounge", type: "campus-building", location: "12287 University Blvd., Orlando, FL 32817", mon: "8pm - 2am", wed: "8pm - 2am", thurs: "8pm - 2am", fri: "8pm - 2am", sat: "8pm - 2am"
# Partner.create name: "Knight Library", type: "library", location: "11448 University Blvd., Orlando, FL 32817", mon: "4pm - 2am", tues: "4pm - 2am", wed: "4pm - 2am", thurs: "4pm - 2am", fri: "4pm - 2am", sat: "4pm - 2am", sun: "4pm - 2am"
# Partner.create name: "Mad Hatter", type: "food", location: "4498 N Alafaya Trail Suite 248, Orlando, FL 32826", mon: "7pm - 2am", tues: "7pm - 2am", wed: "7pm - 2am", thurs: "7pm - 2am", fri: "7pm - 2am", sat: "7pm - 2am", sun: "7pm - 2am"
# Partner.create name: "Meridian Hookah Lounge", type: "food", location: "3050 Alafaya Trail Suite 1012, Oviedo, FL 32765", mon: "8pm - 3am", tues: "8pm - 3am", wed: "8pm - 3am", thurs: "8pm - 3am", fri: "8pm - 3am", sat: "8pm - 3am", sun: "8pm - 3am"
# Partner.create name: "Public House", type: "food", location: "12046 Collegiate Way, Orlando, FL 32817", mon: "12pm - 2am", tues: "12pm - 2am", wed: "12pm - 2am", thurs: "12pm - 2am", fri: "12pm - 2am", sat: "12pm - 2am", sun: "12pm - 2am"
# Partner.create name: "World of Beer", type: "food", location: "3402 Technological Avenue, Orlando, FL 32817", mon: "11am - 2am", tues: "11am - 2am", wed: "11am - 2am", thurs: "11am - 2am", fri: "11am - 2am", sat: "11am - 2am", sun: "11am - 2am"

require 'csv'

tickers = {}

CSV.foreach('db/seeds/blist.csv', :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  tickers[row.fields[0]] = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
end

tickers.each do |name, details|
	partner = Partner.find_or_create_by name: name
	partner.update_attributes details
end