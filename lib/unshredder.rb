require 'chunky_png'
# require 'oily_png'
require 'singleton'

class Unshredder
  include Singleton

  def process src
    @image  = ChunkyPNG::Image.from_file src
    @width  = @image.dimension.width
    @height = @image.dimension.height
    render(unshredded).save(src.sub /\.png$/, '-unshredded.png')
  end
  
  private
  def unshredded
    strips = [p = rand(strip_count)]
    loop do
      assemble strips, :right
      assemble strips, :left
      break if strips.count == strip_count
      p = (p + 1) % strip_count
      strips = [p]
    end
    rotate strips
    strips
  end
  
  def assemble strips, direction = :right
    shredded = Array(0...strip_count)
    loop do
      m = best_match strips.send(direction == :right ? :last : :first), shredded
      break if strips.member? m[0]
      strips.insert direction == :right ? strips.count : 0, shredded[m[1]]
    end
  end
  
  def rotate strips
    loop do
      m = best_match strips.first, strips, :left
      break unless m[1] == strips.count - 1
      strips.push strips.shift
    end
  end
  
  # find the best matching strip given a strip
  def best_match strip, shredded, direction = :right, 
    best_distance = nil
    best_position = p = 0
    while p < shredded.count
      if strip != (other = shredded[p])
        d = distance *edges(strip, other, direction)
        if best_distance.nil? || best_distance > d
          best_distance = d
          best_position = p
        end
      end
      p += 1
    end
    [shredded[best_position], best_position, best_distance]
  end
  
  # decipher the width of a strip
  def strip_width
    return @strip_width unless @strip_width.nil?
    
    # map the average distance between columns of pixels
    distances = []
    @width.times{ |n| distances << [ n, distance(n, n + 1) ] }

    # map the average distances into the difference between distances
    distances.map! do |n, d1|
      d2 = distances[n + 1].last rescue distances[n].last
      [ n, (d1 - d2).round.abs ]
    end
    
    # eliminate the calculated differences that are below the mean (plus some 
    # threshold) of the differences calculated
    mean = (distances.reduce(0){ |sum, n| sum + n.last } / distances.count) * 1.5
    distances.delete_if{ |n| n.last <= mean }
    
    # map distances between column indexes (the widths)
    x = 0;
    distances.map!{ |n, _| m = n - x; x = n; m }

    # eliminate the calculated column widths that are below the mean of the 
    # calculated column widths
    mean = distances.reduce(:+) / distances.count
    distances.delete_if{ |n| n <= mean }
    
    # map the frequencies of each (of the remaining) column width
    freq = distances.inject(Hash.new(0)){ |h, v| h[v] += 1; h }
    
    # column width with the highest frequency is *very likely* the width
    # of strip (assuming all strips are of the same width)
    @strip_width = distances.sort_by{ |v| freq[v] }.last + 1
  end
  
  # calculate the number of strips of a shredded image
  def strip_count
    @strip_count ||= (@width / strip_width).round
  end
  
  # calculate the average color distance between columns
  def distance i, j
    c1 = @image.column(i)
    c2 = @image.column(j % @width)
    Array.new(@height){ |n| color_distance(c1[n], c2[n]) }.reduce(:+) / @height
  end

  def color_distance c1, c2
    dist red(c1), green(c1), blue(c1), red(c2), green(c2), blue(c2)
  end
  
  def dist x1, y1, z1, x2, y2, z2
    Math.sqrt sqr(x2 - x1) + sqr(y2 - y1) + sqr(z2 - z1)
  end
  
  def edges strip, other, direction = :right
    case direction
    when :right then [edge(strip, :right), edge(other, :left)] 
    when :left  then [edge(strip, :left), edge(other, :right)]
    end
  end

  def edge column, direction = :right
    n = column * strip_width
    direction == :right ? n + (strip_width - 1) : n 
  end

  def sqr n 
    n ** 2
  end
  
  def red c 
    ChunkyPNG::Color.r c 
  end
  
  def green c 
    ChunkyPNG::Color.g c 
  end
  
  def blue c 
    ChunkyPNG::Color.b c
  end

  def render strips
    image = ChunkyPNG::Image.new(@width, @height)
    strips.each_with_index do |n, i|
      strip = @image.crop edge(n, :left), 0, strip_width, @height
      image.replace! strip, edge(i, :left), 0
    end
    image
  end
end
