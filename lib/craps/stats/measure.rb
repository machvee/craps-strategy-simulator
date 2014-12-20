class Measure
  #
  # keep totals, avg, min and max for ongoing measurement of an quantity
  # e.g. Number of points a shooter made during his turn
  #
  # incr and commit provide a way to count occurences then commit them
  # as a measure
  #
  attr_reader   :name

  attr_reader   :tally  # ongoing counter
  attr_reader   :count  # number of times measured
  attr_reader   :total  # ongoing total
  attr_reader   :min    # ongoing min
  attr_reader   :max    # ongoing max

  DEFAULT_HISTORY_LENGTH = 40 # keep the last 40 results

  def initialize(name, options = {})
    @name = name
    @last_history = RingBuffer.new(options[:history_length]||DEFAULT_HISTORY_LENGTH)
    reset
  end

  def incr(val=1)
    @tally += val
  end

  def commit
    add(tally)
    @tally = 0
  end

  def add(measurement)
    Array(measurement).each do |m|
      @count += 1
      @total += m
      keep_min(m)
      keep_max(m)
      @last_history << m
    end
    self
  end

  def last(n=1)
    l = @last_history.last(n)
    n > 1 ? l : l.first
  end

  def reset
    @tally = 0
    @count = 0
    @total = 0
    @min = nil
    @max = nil
    @last_history.clear
  end

  def to_s
    "#{name} - count: %d, total: %d, min: %s, max: %s, avg: %s" % [count, total, min||'-', max||'-', average||'-']
  end

  def inspect
    to_s
  end

  def average
   return "0.00" if count == 0
   a = (total * 1.0)/count
   "%6.2f" % a
  end

  private

  def keep_min(measurement)
    @min = measurement if @min.nil? || @min > measurement
  end

  def keep_max(measurement)
    @max = measurement if @max.nil? || @max < measurement
  end

end
