require 'table_stats_collection'

class CrapsStats < TableStatsCollection

  private

  def init_stats
    add OccurrenceStat.new('winners', table_off_p) {table.front_line_winner?}
    add OccurrenceStat.new('craps', table_off_p) {table.crapped_out?}
    add OccurrenceStat.new('points', table_off_p) {table.point_established?}
    add OccurrenceStat.new('points_made', table_on_p) {table.point_made?}
    add OccurrenceStat.new('seven_outs', table_on_p) {table.seven_out?}
    add Table::POINTS.map {|v|
      [OccurrenceStat.new('points_%d' % v, point_established_p) {table.point_established?(v)},
       OccurrenceStat.new('points_made_%d' % v, point_is_p(v)) {table.point_made?(v)}]
    }.flatten
    add Table::WINNERS.map {|v|
      OccurrenceStat.new('winners_%d' % v, front_line_winner_p) {table.front_line_winner?(v)}
    }
    add Table::CRAPS.map {|v|
      OccurrenceStat.new('craps_%d' % v, craps_p) {table.crapped_out?(v)}
    }
    add Table::HARDS.map {|v|
      OccurrenceStat.new('hard_%d' % v, is_roll_p(v)) {table.hard?(v)}
    }
  end

  def table_on_p
    Proc.new {table.on?}
  end

  def table_off_p
    Proc.new {table.off?}
  end

  def front_line_winner_p
    Proc.new {table.front_line_winner?}
  end

  def point_established_p
    Proc.new {table.point_established?}
  end

  def craps_p
    Proc.new {table.crapped_out?}
  end

  def is_roll_p(v)
    Proc.new {table.dice.value == v}
  end

  def point_is_p(v)
    Proc.new {table.point == v}
  end

end
