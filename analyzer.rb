require 'nokogiri'
require 'mongoid'
require_relative 'models/page.rb'
require_relative 'models/sensor_data.rb'

env = ENV['ENV'] == 'production' ? :production : :development
Mongo::Logger.logger.level = ::Logger::FATAL
Mongoid.load!("./mongoid.yml", env)

def extract_number(cell_text)
    cell_text.to_f if cell_text.match(/[-+]?([0-9]*\.[0-9]+|[0-9]+)/)
end

def parse_document(page)
    date_string = page.url.match(/[0-9]+/)[0]
    date = Date.new(date_string[0, 4].to_i, date_string[4, 2].to_i, date_string[6, 2].to_i)
    html_doc = Nokogiri::HTML page.content
    rows = html_doc.css('table.datenhellgrauklein tr')
    rows.each do |row|
        cells = row.css('td').to_a
        if cells.length == 15
            sensor_id = cells[0].inner_html.slice(0,3)
            next unless sensor_id.match(/[0-9]{3}/)
            sensor = Sensor.new(sensor_id: sensor_id)
            sensor.upsert
            sensor = Sensor.where(sensor_id: sensor_id).first
            unless SensorData.where(date: date).where(sensor_id: sensor._id).exists?
                sensor_data = SensorData.new(
                    date: date,
                    sensor_id: sensor._id,
                    partikelPM10Mittel: extract_number(cells[1].inner_html),
                    partikelPM10Ueberschreitungen: extract_number(cells[2].inner_html),
                    russMittel: extract_number(cells[3].inner_html),
                    russMax3h: extract_number(cells[4].inner_html),
                    stickstoffdioxidMittel: extract_number(cells[5].inner_html),
                    stickstoffdioxidMax1h: extract_number(cells[6].inner_html),
                    benzolMittel: extract_number(cells[7].inner_html),
                    benzolMax1h: extract_number(cells[8].inner_html),
                    kohlenmonoxidMittel: extract_number(cells[9].inner_html),
                    kohlenmonoxidMax8hMittel: extract_number(cells[10].inner_html),
                    ozonMax1h: extract_number(cells[11].inner_html),
                    ozonMax8hMittel: extract_number(cells[12].inner_html),
                    schwefeldioxidMittel: extract_number(cells[13].inner_html),
                    schwefeldioxidMax1h: extract_number(cells[14].inner_html)
                )
                sensor_data.upsert
            end
        end
    end
end
#puts SensorData.where(date: Date.new(2014, 5, 13)).where(sensor_id: "53a1ed3ba0cb4c3f81000001" ).exists?
#puts SensorData.all.to_a.first.date
def analyse!()
    Page.all.map { |e| parse_document(e) }
end