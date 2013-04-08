

# A trajectory is a collection of samples.
class Trajectory
  include TrajectoryMetrics
  attr_accessor :samples, :name, :description

  def initialize(samples, options)
    @samples = samples
    @name = options[:name] || '(no name)'
    @description = options[:description] || '(no description)'
  end

  # create a duplicate trajectory
  def dup
    Trajectory.new(self.points.map(&:dup))
  end

  # Remove (N-1) in N number of points, where N is rate
  def simplify(rate)
    new_samples = []
    (0...samples.length).each do |i|
      if i % rate == 0
        new_samples << samples[i]
      end
    end

    self.samples = new_samples
  end

  def first
    self.samples.first
  end

  def last
    self.samples.last
  end

  # Write a kml file that captures this sample
  def write_to_file(filepath)
    str = ''
    builder = Builder::XmlMarkup.new(:indent => 2)

    builder.Document do |b|
      (0...24).each do |hour|
        b.Folder do |b|
          b.name("hour #{hour}")

          _samples = self.samples.select {|x| x.date.hour == hour }
          _samples.each do |sample|
            builder.Placemark do |b|
              b.name(sample.date.strftime('%c'))
              b.Point do |b|
                b.coordinates("#{sample.lon},#{sample.lat}")
              end
            end
          end

        end
      end
    end

    str = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2">'
    str << builder.target!
    str << '</kml>'

    f = File.open(filepath, 'w')
    f.write(str)
    f.close
  end

  def self.hour_histogram(trajectories)
    counts = (0...24).reduce({}) {|hash, hour| hash[hour] = 0; hash }
    trajectories.each do |traj|
      traj.samples.each do |sample|
        hour = sample.date.hour
        counts[hour] += 1
      end
    end

    counts
  end

  def sample_rate

    time_deltas = []
    samples.each_with_index do |sample, i|
      next if i == 0
      prev_sample = samples[i - 1]
      delta_seconds = ((sample.date - prev_sample.date) * 24.0 * 60.0 * 60.0).to_f
      time_deltas << delta_seconds
    end

    time_deltas.sort!
    time_deltas = time_deltas.to_vector
    {
      :mean => time_deltas.mean,
      :median => time_deltas.median_from_sorted_data,
      :std_dev => time_deltas.sd,
      :max => time_deltas.max,
      :min => time_deltas.min
    }
  end

  # Run kmeans clustering on the (unordered) samples in the trajectory
  # WIP
  def points_clusters
    puts "Running k-means on #{samples.length} points of data"
    data = samples.map{|x| [x.lon, x.lat] }
    kmeans = KMeans.new(data, :centroids => 5)
    kmeans.inspect
    require 'pry'; binding.pry
  end

  # Combine the trajectories into one larger trajectory
  def self.combine(trajectories)
    samples = []
    trajectories.each {|traj| samples += traj.samples }

    Trajectory.new(samples)
  end

  # Combine the trajectories into one larger trajectory
  def combine(*args)
    if args.class != Array
      args = [args]
    end

    args.each {|x| self.samples += x.samples}
    samples.sort_by! {|sample| sample.date}

    self
  end

  # Return a new trajectory that only includes samples that were taken
  # during the hours given
  def filter_by_hours(hours)
    Trajectory.new(
      samples.select do |sample|
        hours.include?(sample.date.hour)
      end
    )
  end
end


# A sample is combination of a location and time.
# Many samples can make up a trajectory.
class Sample
  attr_accessor :date, :point, :altitude
  def initialize(attrs)
    @date = attrs[:date]

    if attrs[:lat] && attrs[:lon]
      factory = ::RGeo::Geographic.simple_mercator_factory()
      @point = factory.point(attrs[:lon].delete, attrs[:lat].delete)
    end
    @point = attrs[:point].delete if attrs[:point]
    @altitude = attrs[:altitude].delete

    @values = attrs || {}
  end

  def time
    self.date
  end

  def method_missing(m, *args, &block)
    m_str = m.to_s
    if m_str[-1] == '='
      k = m_str[(0...m_str.length - 1)].to_sym

      if @values[k]
        return @values[k] = args.first
      end
    else
      if @values[m.to_sym]
        return @values[m.to_sym]
      end
    end

    super(m, args, &block)
  end

  def lat
    @point.lat
  end

  def lon
    @point.lon
  end
end


class Array
  def to_vector
    GSL::Vector[*self]
  end
end

#<?xml version="1.0" encoding="UTF-8"?>
#<kml xmlns="http://www.opengis.net/kml/2.2">
#  <Placemark>
#    <name>Simple placemark</name>
#    <description>Attached to the ground. Intelligently places itself
#       at the height of the underlying terrain.</description>
#    <Point>
#      <coordinates>-122.0822035425683,37.42228990140251,0</coordinates>
#    </Point>
#  </Placemark>
#</kml>
