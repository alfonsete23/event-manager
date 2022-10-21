require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def add_hours_and_days(time, registration_hours, registration_days)
    hour = Time.strptime(time, "%m/%d/%Y %k:%M").hour.to_s
    if registration_hours.key?(hour)
        registration_hours[hour] += 1
    else
        registration_hours[hour] = 1
    end

    day = Date::DAYNAMES[Date.strptime(time, "%m/%d/%Y %k:%M").wday]

    if registration_days.key?(day)
        registration_days[day] += 1
    else
        registration_days[day] = 1
    end
end

def clean_phone(phone)
    phone = phone.gsub(/[^\d]/, "")
    if phone.length < 10 || phone.length > 11
        return "NOT VALID"
    elsif phone.length == 10
        return phone
    elsif phone[0] == "1"
        phone.slice(0, 1)
        return phone
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exist?("output")

    filename = "output/thanks_#{id}.html"

    File.open(filename, "w") do |file|
        file.puts form_letter
    end
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zipcode,
            levels: "country",
            roles: ["legislatorUpperBody", "legislatorLowerBody"]
        ).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
end

sample_file = "event_attendees.csv"
template_file = "form_letter.erb"

# check if file exists
unless File.exist?(sample_file)
    puts "File #{sample_file} not found."
    exit(1)
end

#open csv
contents = CSV.open(sample_file, headers: true, header_converters: :symbol)

template_letter = File.read(template_file)
erb_template = ERB.new(template_letter)

registration_hours = {}
registration_days = {}
# iterate through all the rows
contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    # Phone number cleaning
    phone = clean_phone(row[:homephone])

    add_hours_and_days(row[:regdate], registration_hours, registration_days)

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

end

# Hash with the amount of people registered at every hour
puts registration_hours
# Hash with the amount of people registered at every day of the week
puts registration_days