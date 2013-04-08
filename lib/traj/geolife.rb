
module GeoLife
  GEOLIFE_PATH = './data/Geolife Trajectories 1.3/Data'

  def rgeo_factory
    ::RGeo::Geographic.simple_mercator_factory()
  end

  class FileReader
    def self.get_user_trajectories(user_id, limit=nil)
      user_dir = sprintf('%03d', user_id)
      files = Dir.glob("#{GEOLIFE_PATH}/#{user_dir}/**/*.plt")
      if limit
        files.slice!(0, limit)
      end

      files.map do |filepath|
        samples = GeoLife::FileReader.read(filepath)
        t = Trajectory.new(samples, samples.first.date.to_s)
        t.simplify(60)
        t
      end
    end

    def self.read(filepath)
      puts "Reading file: #{filepath}"
      lines = File.readlines(filepath)
      headers = lines.slice!((0...6))

      items = lines.map do |line|
        self.process_row(line.strip.split(','))
      end
    end

    def self.process_row(columns)
      #Field 1: Latitude in decimal degrees.
      #Field 2: Longitude in decimal degrees.
      #Field 3: All set to 0 for this dataset.
      #Field 4: Altitude in feet (-777 if not valid).
      #Field 5: Date - number of days (with fractional part) that have passed since 12/30/1899.
      #Field 6: Date as a string.
      #Field 7: Time as a string.

      altitude = columns[3] == '-777' ? nil : columns[3].to_f
      d = Date._parse("#{columns[5]}T#{columns[6]}+00:00")
      date = Time.new(d[:year], d[:month], d[:mday], d[:hour], d[:minute], d[:sec]).localtime("+08:00")

      Sample.new({
        :lat => columns[0].to_f,
        :lon => columns[1].to_f,
        :altitude => altitude,
        :date => date
      })
    end

  end
end

