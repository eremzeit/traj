class TrajectoriesSummarizer
  def initialize(trajectories)
    @trajectories = trajectories
  end

  def make_rows
    rows = []
    rows << ['start_date', 'end_date', 'duration(hours)', 'mean_sample_rate', 'std_dev_sample_rate', 'distance_traveled']

    rows += @trajectories.map do |traj|
      start_date = traj.first.date.strftime('%c')
      end_date = traj.last.date.strftime('%c')
      average_sample_rate = traj.sample_rate[:mean]
      std_dev_sample_rate = traj.sample_rate[:std_dev]

      #TODO: is this right?
      duration_hours = ((traj.last.date - traj.first.date) * 24.0).to_f
      [start_date, end_date, duration_hours, average_sample_rate, std_dev_sample_rate]
    end
  end

  def output
    make_rows.reduce('') do |output, row|
      output << row.map{|x| '"' + x.to_s + '"'}.join("\t")
      output << "\n"
    end
  end

  def self.write(filepath, trajectories)
    File.open(filepath, 'w') do |file|
      file.write(TrajectoriesSummarizer.new(trajectories).output)
    end
  end

  def self.write_trajectory_sets(filepath, trajectory_sets)
    File.delete(filepath)
    File.open(filepath, 'a') do |file|
      trajectory_sets.each do |trajectories|
        s = TrajectoriesSummarizer.new(trajectories).output + "\n"
        s << Trajectory.hour_histogram(trajectories).to_a.map {|x| "#{x[0]}: #{x[1]}"}.join(' ')
        file.write(s)

      end
    end
  end
end

