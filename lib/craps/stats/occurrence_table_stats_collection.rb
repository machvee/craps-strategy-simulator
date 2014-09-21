class OccurrenceTableStatsCollection < StatsCollection

  attr_reader :table

  def initialize(name, options = {})
    super
    @table = options[:table]
  end

  private

  def child_stat_factory(parent_stat)
    OccurrenceStat.new(
      parent_stat.name,
      lost_condition: parent_stat.lost_condition,
      &parent_stat.won_condition
    )
  end
end
