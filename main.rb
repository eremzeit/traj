require './lib/traj'

def test_summarizer
  trajs = GeoLife::FileReader.get_user_trajectories(172)
  TrajectoriesSummarizer.write('test.csv', trajs)
end

def test_summarizer_multiple
  trajs = (11...12).map { |i| GeoLife::FileReader.get_user_trajectories(i) }
  TrajectoriesSummarizer.write_trajectory_sets('test.csv', trajs)
end

def test_clustering
  trajs = GeoLife::FileReader.get_user_trajectories(11)
  traj = Trajectory.combine(trajs)
  traj.simplify(60)
  traj = traj.filter_by_hours((0..4).to_a)
  traj.write_to_file('output.kml')
  traj.points_clusters
end

def test_histogram
  #trajs = GeoLife::FileReader.get_user_trajectories(11)
  trajs = GeoLife::FileReader.get_user_trajectories(11)
  trajs.map! {|traj| traj.filter_by_hours([0,1,2,4,5])}

  points = trajs.map {|t| t.samples.map {|sample| sample.point }}.flatten

  h = PointHistogram.new(points)
  buckets = h.full_info.values.select do |bucket|
    bucket[:count] > 10
  end

  point_infos = buckets.map do |bucket|
    {
      :name => bucket[:count],
      :lat => bucket[:lat],
      :lon => bucket[:lon]
    }
  end

  KmlWriter.write_folders('histogram.kml') do |builder|
    KmlWriter.trajectories_folders(builder, trajs)
    KmlWriter.points_folder(builder, point_infos, '2D Buckets')
  end
end

def test_kml_builder
  trajs = GeoLife::FileReader.get_user_trajectories(146)

  KmlWriter.write_folders('folder_writing.kml') do |builder|
    KmlWriter.trajectory_folder(builder, trajs.first)
    KmlWriter.trajectory_folder(builder, trajs.last)
  end
end

def test_user_analysis
  #trajs = GeoLife::FileReader.get_user_trajectories(11)
  trajs = GeoLife::FileReader.get_user_trajectories(146)
  UserAnalysis.new(trajs).perform
end

#test_summarizer_multiple
#test_clustering
#test_histogram
#test_kml_builder
test_user_analysis

