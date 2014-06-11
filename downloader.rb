require 'mongoid'
require 'httparty'
require_relative 'page.rb'

def check_and_download!
    # we will crawl from 2008-01-01 until today
    env = ENV['ENV'] == 'production' ? :production : :development
    Mongoid.load!("./mongoid.yml", env)

    start_date = Date.new(2008, 1, 1)
    days_to_check = Date.today - start_date
    base_url = 'http://www.stadtentwicklung.berlin.de/umwelt/luftqualitaet/de/messnetz/tageswerte/download/%s.html'
    for i in 0..days_to_check do
        current_date = Date.today - i
        url_id = current_date.strftime('%Y%m%d')
        url_to_download = base_url % url_id
        date_is_recent = Date.today - current_date < 5
        page_already_exists = Page.where(url: url_to_download).exists?
        unless page_already_exists && !date_is_recent
            response = HTTParty.get(url_to_download)
            body = response.body.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
            if page_already_exists
                page = Page.where(url: url_to_download).first
                page.update_attributes!(
                  content: body,
                  date_download: DateTime.now
                )
                puts 'Updated %s' % url_id
            else
                Page.create(
                  content: body,
                  url: url_to_download,
                  date_download: DateTime.now
                )
                puts 'Inserted %s' % url_id
            end
            sleep(1)
        end
    end
end