require 'table_stats_collection'

class RollStats < TableStatsCollection

  def init_stats
    [
      OccurrenceStat.new('total_rolls') {true},
      *[*table.dice_value_range].map {|v|
        OccurrenceStat.new('rolled_%d' % v){table.last_roll == v}
      }
    ]
  end
end
