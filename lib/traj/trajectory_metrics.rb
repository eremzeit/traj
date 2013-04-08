# A grouping of different methods that calculate metrics about trajectory
#
# TODO: shouldn't this be defined as a module rather than a class?
class TrajectoryMetrics

  def perform_calculations
    calculate_velocities
    calculate_accelerations
  end

  # This method is a naive implementation.  Could use binary search because we know the
  #   points are ordered.
  # @param forward_seconds [Fixnum] Only include samples that are before this time (exclusive)
  # @param backward_seconds [Fixnum] Only include samples that are after this time (exclusive)
  def moving_time_window(forward_seconds, backward_seconds)
    samples.each_with_index do |i|
      pre_window, post_window = nil, nil

      current = samples[i]
      if i != 0
        offset = -1
        while i + offset >= 0 && (current.time - samples[i + offset].time) <= backward_seconds
          offset -= 1
        end
      end

      pre_window = (i + (offset + 1)..i - 1)

      if i != samples.length - 1
        offset = 1
        while i + offset < samples.length && (samples[i + offset].time - current.time) <= forward_seconds
          offset += 1
        end
      end

      post_window = (i + 1..i + (offset - 1))
      yield(pre_samples, current_sample, post_samples)
    end
  end

  def each_point
    samples.each_with_index do |i|
      sample_a = i != 0 ? samples[i-1] : nil
      sample_b = samples[i]
      sample_c = i != samples.length - 1 ? samples[i+1] : nil

      yield(sample_a, sample_b, sample_c)
    end
  end

  #
  # a_________B__________c
  #
  # Velocity is estimated to be the average of the velocity
  # between a and b and the velocity between b and c
  def calculate_velocities
    each_point do |sample_a, sample_b, sample_c|
      sample_b.velocity = self.class._velocity_b(sample_b, sample_b, sample_c)
    end
  end

  def calculate_accelerations
    each_point do |sample_a, sample_b, _|
      sample_b.acceleration = self.class._acceleration_b(sample_a, sample_b)
    end
  end

  # a_________B__________c
  # Accelation at point B is estimated to be the change in velocity
  # from point a to point b
  # Assumes that the velocities have already be calculated
  # @return [Fixnum] acceleration of sample_b
  def self._acceleration_b(sample_a, sample_b)
    if sample_a.present?
      v_diff_a_b = sample_b.velocity - sample_a.velocity
      time_diff_a_b = sample_b.time - sample_a.time
      v_diff_a_b / time_diff_a_b
    else
      nil
    end

  end

  #
  #      P         Q
  # a_________b__________c
  #
  # Velocity is estimated to be the average of the velocity
  # between a and b and the velocity between b and c.
  # @return [Fixnum] velocity of sample_b
  def self._velocity_b(sample_a, sample_b, sample_c)
    velocity_a_b = nil
    velocity_b_c = nil

    if sample_a.present?
      dist_a_b = sample_a.point.distance(sample_b.point)
      time_diff_a_b = sample_b.time - sample_a.time
      velocity_a_b = dist_a_b / time_diff_a_b
    end

    if sample_b.present?
      dist_b_c = sample_b.point.distance(sample_c.point)
      time_diff_b_c = sample_c.time - sample_b.time
      velocity_b_c = dist_b_c / time_diff_b_c
    end

    velocity_a_b ||= velocity_b_c
    velocity_b_c ||= velocity_a_b

    (velocity_a_b + velocity_b_c / 2.0)
  end
end
