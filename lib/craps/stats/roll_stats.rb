require 'occurrence_table_stats_collection'

class RollStats < OccurrenceTableStatsCollection
  def initialize(name, craps_table, options = {})
    super
    add [*craps_table.dice_tray.dice_value_range].map { |v|
      OccurrenceStat.new('rolled_%d' % v) {craps_table.last_roll == v}
    }
  end
end
