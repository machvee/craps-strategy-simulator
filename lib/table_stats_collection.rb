require 'occurrence_stat'

class TableStatsCollection
  attr_reader :name
  attr_reader :table
  attr_reader :stats

  def initialize(name, table)
    @name = name
    @table = table
    @stats = []
    @lkup = {}
  end

  def update
    stats.each(&:update)
    return
  end

  def reset
    stats.each(&:reset)
    return
  end

  def print(occurrence_header_options={})
    puts table_print_header
    puts OccurrenceStat.print_header(occurrence_header_options)
    stats.each do |stat|
      puts stat
    end
    return
  end

  def each
    stats.each {|s| yield s if block_given?}
  end

  def new_instance(new_name)
    #
    # clone the current table stats collection
    #
    tsc = TableStatsCollection.new(new_name, table)
    each do |stat|
      new_stat = OccurrenceStat.new(
        stat.name,
        stat.lost_condition,
        &stat.won_condition)
      tsc.add(new_stat)
    end
    tsc
  end
  
  def update_from_hash(stats_hash)
    # stats_hash is {stat_name => WON/LOST, ...}
    stats_hash.each_pair do |stat_name, val|
      case val
        when OccurrenceStat::WON
          won(stat_name)
        when OccurrenceStat::LOST
          lost(stat_name)
      end
    end
  end

  def won(stat_name)
    @lkup[stat_name].won
  end

  def lost(stat_name)
    @lkup[stat_name].lost
  end

  def incr(stat_name)
    @lkup[stat_name].incr
  end

  def inspect
    print
  end

  def add(stat)
    Array(stat).each do |stat|
      @stats << stat
      @lkup[stat.name] = stat
      make_won_convenience_methods(stat)
    end
  end

  def stat_by_name(name)
    @stats.find {|s| s.name == name}
  end

  private

  def make_won_convenience_methods(stat)
    #
    # be careful not to make stats names that conflict with defined methods above
    #
    self.class.instance_eval do
      define_method(stat.name) do |option=OccurrenceStat::WON|
        stat.total(option)
      end
    end
  end

  def table_print_header
    "#{name} statistics - #{Time.now.to_s(:db)}"
  end
end
