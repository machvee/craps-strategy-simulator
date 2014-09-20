class StatsCollection
  attr_reader :name
  attr_reader :stats
  attr_reader :parent_stats
  attr_reader :column_headers_format

  DEFAULT_OUTPUT_FORMATTER = "%20s    %10s      %10s / %10s      %10s / %10s"

  DEFAULT_COLUMN_LABELS = {
    name:          'name',
    count:         'count',
    won:           'won',
    win_streak:    'win streak',
    lost:          'lost',
    losing_streak: 'lose streak'
  }

  def initialize(name, options = {})
    @name = name
    @stats = []
    @lkup = {}
    @options = options
    @parent_stats = options[:parent_stats]
    @column_headers_format = DEFAULT_OUTPUT_FORMATTER
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
    puts print_collection_header
    puts print_column_header(header_options)
    stats.each do |stat|
      puts column_headers_format % stat.attrs
    end
    return
  end

  def each
    stats.each {|s| yield s if block_given?}
  end

  def new_child_instance(new_name)
    #
    # clone the current stats collection
    #
    new_child_collection = self.class.new(new_name, @options.merge(parent_stats: self))
    each do |stat|
      new_stat = child_stat_factory(stat)
      new_child_collection.add(new_stat)
    end
    new_child_collection
  end

  def won(stat_name, options = {})
    stat_by_name(stat_name).won(options)
  end

  def lost(stat_name, options = {})
    stat_by_name(stat_name).lost(options)
  end

  def incr(stat_name, options = {})
    stat_by_name(stat_name).incr(options)
  end

  def inspect
    print
  end

  def add(stats)
    Array(stats).each do |s|
      init_stat(s)
    end
  end

  def stat_by_name(name)
    @lkup[name] || raise("no stat in collection with name '#{name}'")
  end

  private

  def child_stat_factory(parent_stat)
    parent_stat.class.new(parent_stat.name)
  end
  
  def init_stat(stat)
    @stats << stat
    @lkup[stat.name] = stat
    make_stat_convenience_methods(stat)
    link_to_parent(stat)
  end

  def link_to_parent(stat)
    return if parent_stats.nil?
    stat.parent_stat = parent_stats.stat_by_name(stat.name)
  end

  def make_stat_convenience_methods(stat)
    #
    # be careful not to make stats names that conflict with defined methods above
    #
    self.define_singleton_method(stat.name.to_sym) do
      stat
    end
  end

  def print_column_header(options={})
    labels = column_labels.merge(options)

    column_headers_format % column_headers
  end

  def column_labels
    DEFAULT_COLUMN_LABELS
  end

  def column_headers
    [
      column_labels[:name],
      column_labels[:count],
      column_labels[:won],
      column_labels[:win_streak],
      column_labels[:lost],
      column_labels[:losing_streak]
    ]
  end

  def print_collection_header
    "#{name} statistics - #{Time.now.to_s(:db)}"
  end
end
