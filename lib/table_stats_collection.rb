require 'occurrence_stat'

class TableStatsCollection
  attr_reader :table
  attr_reader :stats

  def initialize(table)
    @table = table
    @stats = []
    init_stats.each do |stat|
      add stat
    end
  end

  def init_stats
    # optional subclass override with initial stats created at new
    []
  end

  def update
    stats.each(&:update)
    return
  end

  def reset
    stats.each(&:reset)
    return
  end

  def print
    puts OccurrenceStat.print_header
    stats.each do |stat|
      puts stat
    end
    return
  end

  def each
    stats.each {|s| yield s if block_given?}
  end

  def inspect
    print
  end

  def add(stat)
    Array(stat).each do |stat|
      @stats << stat
      make_occurred_convenience_methods(stat)
    end
  end

  private

  def make_occurred_convenience_methods(stat)
    #
    # be careful not to make stats names that conflict with defined methods above
    #
    self.class.instance_eval do
      define_method(stat.name) do
        stat.total
      end
    end
  end
end
