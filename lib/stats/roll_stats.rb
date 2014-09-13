require 'table_stats_collection'

class RollStats < TableStatsCollection

  def initialize(name, table)
    super
    add [*table.dice_tray.dice_value_range].map { |v|
      OccurrenceStat.new('rolled_%d' % v) {table.last_roll == v}
    }
  end
end
