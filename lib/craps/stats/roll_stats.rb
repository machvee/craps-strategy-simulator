require 'occurrence_table_stats_collection'

class RollStats < OccurrenceTableStatsCollection
  def initialize(name, options = {})
    super
    add [*table.dice_tray.dice_value_range].map { |v|
      OccurrenceStat.new('rolled_%d' % v) {table.last_roll == v}
    }
  end
end
