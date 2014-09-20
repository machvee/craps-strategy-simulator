require 'stats_collection'

class CountersStatsCollection < StatsCollection
  attr_reader :counter_names

  def initialize(name, options)
    super
    setup_counters(options[:counter_names]||[])
  end

  private

  def init_stat(stat)
    super
    stat.set_counters(counter_names) unless counter_names.empty?
  end

  def column_labels
    @_labels ||= super.merge(Hash[*counter_names.map {|n| [n.to_sym, n.to_s]}.flatten])
  end

  def column_headers(labels)
    super + counter_names.map {|n| column_labels[n.to_sym]}
  end

  def setup_counters(counter_names)
    @counter_names = counter_names
    return if counter_names.empty?

    extra_formatting = counter_names.map{|n| "%10s"}.join(" / ")
    @column_headers_format = DEFAULT_OUTPUT_FORMATTER + extra_formatting
  end
end
