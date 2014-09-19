module Craps
  require 'table_stats_collection'

  class RollStats < TableStatsCollection
    def initialize(name, craps_table, parent_table=nil)
      super
      add [*craps_table.dice_tray.dice_value_range].map { |v|
        Stat.new('rolled_%d' % v) {table.last_roll == v}
      }
    end
  end
end
