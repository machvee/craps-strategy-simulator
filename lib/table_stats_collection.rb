require 'occurrence_stat'

class TableStatsCollection
  attr_reader :table
  attr_reader :stats

  def initialize(table)
    @table = table
    @stats = []
    init_stats
    make_occurred_convenience_methods
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
    @stats += Array(stat)
  end

  private

  def init_stats
    [] # override this method with your OccurenceStat.new() array
  end

  def make_occurred_convenience_methods
    #
    # be careful not to make stats names that conflict with defined methods above
    #
    each do |s|
      self.class.instance_eval do
        define_method(s.name) do
          s.total
        end
      end
    end
  end
end
