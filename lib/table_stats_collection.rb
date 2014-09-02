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
        stat.not_occurred_condition,
        &stat.occurred_condition)
      tsc.add(new_stat)
    end
    tsc
  end

  def occurred(stat_name)
    @lkup[stat_name].occurred
  end

  def did_not_occur(stat_name)
    @lkup[stat_name].did_not_occur
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
      make_occurred_convenience_methods(stat)
    end
  end

  def stat_by_name(name)
    @stats.find {|s| s.name == name}
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

  def table_print_header
    "#{name} statistics - #{Time.now.to_s(:db)}"
  end
end
