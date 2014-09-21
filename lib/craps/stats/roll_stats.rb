class RollStats < OccurrenceTableStatsCollection
  def initialize(name, options = {})
    super
  end

  def add_stats
    add [*table.dice_tray.dice_value_range].map { |v|
      OccurrenceStat.new('rolled_%d' % v) {table.last_roll == v}
    }
  end
end
