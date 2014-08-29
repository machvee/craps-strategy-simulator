require 'table_stats_collection'

class RollStats < TableStatsCollection

  private

  def last_roll
    table.last_roll
  end

  def init_stats
    add OccurrenceStat.new('total_rolls') {true}
    add possible_rolls.map {|v| OccurrenceStat.new('rolled_%d' % v){last_roll == v}}
  end

  def possible_rolls
    [*table.dice_value_range]
  end
end
