class KmlWriter
  TRAJECTORY_ICON = 'http://www.help2engg.com/images/dot.png'
  REFERENCE_POINT_ICON = 'http://http://imgur.com/e2He6w3'

  def self.write_folders(filepath)
    str = ''
    builder = Builder::XmlMarkup.new(:indent => 2)

    builder.Document do |b|
      yield(b)
    end

    str = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2">'
    str << builder.target!
    str << '</kml>'

    f = File.open(filepath, 'w')
    f.write(str)
    f.close
  end

  def self.trajectories_folders(builder, trajectories, name = nil)
    name ||= 'trajectories'
    builder.Folder do |b|
      trajectories.each do |traj|
        b.name(name)
        self.trajectory_folder(b, traj)
      end
    end
  end

  def self.trajectory_folder(builder, trajectory)
    builder ||= Builder::XmlMarkup.new(:indent => 2)

    builder.Folder do |b|
      b.name(trajectory.name)
      b.description(trajectory.description)
      trajectory.samples.each {|sample| sample_placemark(b, sample, TRAJECTORY_ICON) }
    end

    builder
  end

  def self.points_folder(builder, point_infos, name = nil, icon_href = nil)
    name ||= 'Points folder'

    if !point_infos.empty? && point_infos.first.class != Hash
      raise ArgumentError.new('point_infos should be a list of hashes')
    end

    builder.Folder do |b|
      b.name(name)

      point_infos.each do |point_info|
        b.Placemark do |b|
          b.name(point_info[:name])
          b.description(point_info[:description]) if point_info[:description]
          self.icon(b, REFERENCE_POINT_ICON)
          b.Point do |b|
            b.coordinates("#{point_info[:lon]},#{point_info[:lat]}")
          end
        end
      end
    end
    builder
  end

  def self.sample_placemark(builder, sample, icon_href = nil)
    builder ||= Builder::XmlMarkup.new(:indent => 2)
    builder.Placemark do |b|
      b.name(sample.date.strftime('%c'))
      self.icon(b, icon_href)
      b.Point do |b|
        b.coordinates("#{sample.lon},#{sample.lat}")
      end
    end
    builder
  end

  def self.icon(builder, href)
    builder.icon do |b|
      b.href(href)
      b.refreshMode('onChange')
    end
    builder
  end
end

