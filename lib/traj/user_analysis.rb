class UserAnalysis
  def initialize(trajectories)
    @trajectories = trajectories
    @samples = trajectories.map {|t| t.samples }.flatten
  end

  def sample_to_hash(sample)
    {
      :name => sample.date.strftime('%y-%m-%d %H:%M'),
      :lat => sample.lat,
      :lon => sample.lon
    }
  end

  def samples_by_hour
    return @by_hour if @by_hour

    by_hour = (0...24).reduce({}) {|hash, hour| hash[hour] = []; hash }
    @by_hour = @samples.reduce(by_hour) {|hash, sample| hash[sample.date.hour] << sample; hash;}
  end

  # Returns a hash, keyed on hour of the day, where each value is a
  # array of hashes, each hash describing a geospatial bucket and it's count
  def make_histograms_by_hour
    _by_hour = samples_by_hour.dup
    _by_hour.each_key do |hour|
      hour_samples = _by_hour[hour]
      next if hour_samples.length < 2
      histogram = PointHistogram.new(hour_samples)
      buckets = histogram.calculate

      point_infos = buckets.map do |bucket|
        {
          :name => bucket[:count],
          :lat => bucket[:lat],
          :lon => bucket[:lon]
        }
      end

      _by_hour[hour] = point_infos
    end

require 'pry'; binding.pry
    _by_hour
  end

  def _build_points_by_hour(builder)
    builder.Folder do |b|
      b.name('Points by hour')
      samples_by_hour.each_pair do |hour, samples|
        samples = samples.map{|sample| sample_to_hash(sample)}
        KmlWriter.points_folder(b, samples, hour)
      end
    end
  end

  def _build_histogram_by_hour(builder)
    builder.Folder do |b|
      b.name('Histogram by hour')
      make_histograms_by_hour.each_pair do |hour, buckets|
        require 'pry'; binding.pry
      end
    end
  end

  def _build_trajectories(builder)
    KmlWriter.trajectories_folders(builder, @trajectories)
  end

  def perform
    KmlWriter.write_folders('histogram.kml') do |builder|
      _build_trajectories(builder)
      _build_points_by_hour(builder)
      _build_histogram_by_hour(builder)
    end
  end
end
