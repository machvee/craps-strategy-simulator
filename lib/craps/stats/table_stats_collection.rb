require 'stat'
class TableStatsCollection
  attr_reader :name
  attr_reader :table
  attr_reader :stats
  attr_reader :parent_stats
  attr_reader :optional_counter_names
  attr_reader :column_headers_format

  DEFAULT_OUTPUT_FORMATTER = "%20s    %10s      %10s / %10s      %10s / %10s"

  DEFAULT_COLUMN_LABELS = {
    name:          'name',
    count:         'total',
    won:           'won',
    win_streak:    'win streak',
    lost:          'lost',
    losing_streak: 'lose streak'
  }

  def initialize(name, table, optional_counter_names=[], parent_stats = nil)
    @name = name
    @table = table
    @stats = []
    @lkup = {}
    setup_optional_counters(optional_counter_names||[])
    @parent_stats = parent_stats
  end

  def update
    stats.each(&:update)
    return
  end

  def reset
    stats.each(&:reset)
    return
  end

  def print(header_options={})
    puts print_table_header
    puts print_column_header(occurrence_header_options)
    stats.each do |stat|
      column_headers_format % stat.attrs
    end
    return
  end

  def each
    stats.each {|s| yield s if block_given?}
  end

  def new_child_instance(new_name)
    #
    # clone the current table stats collection
    #
    tsc = TableStatsCollection.new(new_name, table, optional_counter_names, self)
    each do |stat|
      new_stat = Stat.new(
        stat.name,
        stat.lost_condition,
        &stat.won_condition)
      tsc.add(new_stat)
    end
    tsc
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
      stat.set_optional_counters(optional_counter_names) unless optional_counter_names.empty?
      @stats << stat
      @lkup[stat.name] = stat
      make_stat_convenience_methods(stat)
      link_to_parent(stat)
    end
  end

  def stat_by_name(name)
    @lkup[name]
  end

  private

  def link_to_parent(stat)
    return if parent_stats.nil?
    stat.parent_stat = parent_stats.stat_by_name(stat.name)
  end

  def make_stat_convenience_methods(stat)
    #
    # be careful not to make stats names that conflict with defined methods above
    #
    self.class.instance_eval do
      define_method(stat.name) do
        stat
      end
    end
  end

  def print_column_header(options={})
    column_labels = DEFAULT_COLUMN_LABELS.
      merge(Hash[*optional_counter_names.map {|n| [n.to_sym, n.to_s]}.flatten]).
      merge(options)

    column_headers_format % [
      column_labels[:name],
      column_labels[:count],
      column_labels[:won],
      column_labels[:win_streak],
      column_labels[:lost],
      column_labels[:losing_streak],
      *optional_counter_names.map {|n| column_labels[n.to_sym]}
    ]
  end

  def print_table_header
    "#{name} statistics - #{Time.now.to_s(:db)}"
  end

  def setup_option_counters(counter_names)
    @optional_counter_names = counter_names
    return if counter_names.empty?

    extra_formatting = counter_names.map{|n| "%10s"}.join(" / ")
    column_headers_format = DEFAULT_OUTPUT_FORMATTER + extra_formatting
  end
end
