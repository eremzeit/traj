# Given a list of points, generate a 2-d histogram of how many of the points
# fall are within each spatial bucket.
#
class PointHistogram
  def initialize(points, options = {})
    @points = points

    options[:bucket_size_lat] ||= 0.004
    options[:bucket_size_lon] ||= 0.0065

    find_max_min

    if options[:min_x] && options[:max_x] && options[:min_y] && options[:max_y]
      x_diff = @max_x - @min_x
      y_diff = @max_y - @min_y
    end

    @x_width = options[:bucket_size_lon]
    @y_width = options[:bucket_size_lat]

    @x_bucket_count = (x_diff / options[:bucket_size_lon]).ceil
    @y_bucket_count = (y_diff / options[:bucket_size_lat]).ceil

    if x_diff == 0 || y_diff == 0
      raise ArgumentError.new "Invalid starting coordinates for histogram"
    end
  end

  def find_max_min
    @max_y = -1
    @min_y = 9999999
    @max_x = -1
    @min_x = 9999999

    @points.each do |point|
      @max_x = point.lon if point.lon > @max_x
      @min_x = point.lon if point.lon < @min_x
      @max_y = point.lat if point.lat > @max_y
      @min_y = point.lat if point.lat < @min_y
    end
  end

  def _calculate
    histogram = Hash.new(0)

    @points.each do |point|
      xi = xpos_to_xi(point.lon)
      yi = ypos_to_yi(point.lat)
      histogram[[xi, yi]] += 1
    end

    histogram
  end

  def ypos_to_yi(y_pos)
    yoffset = y_pos - @min_y
    yi = (yoffset / @y_width).floor
  end

  def xpos_to_xi(x_pos)
    xoffset = x_pos - @min_x

    xi = (xoffset / @x_width).floor
  end

  # Returns an array of hashes, where each hash describes a bucket and
  #it's contents
  def calculate
    histogram = _calculate
    histogram.keys.map do |xy_i|
      {
        :count => histogram[xy_i],
        :lon => @min_x + xy_i[0] * @x_width + @x_width / 2.0,
        :lat => @min_y + xy_i[1] * @y_width + @y_width / 2.0,
        :x_i => xy_i[0],
        :y_i => xy_i[1]
      }
    end
  end
end
