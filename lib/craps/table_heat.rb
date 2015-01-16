  =begin
  def hot_numbers_average
    point_numbers_rolled.average
  end

  def numbers
    point_numbers_rolled.count
  end

  def reset
    point_numbers_rolled.reset
  end

  point_numbers_rolled.commit

  attr_reader  :numbers # history of number of rolls between ON and OFF
  attr_reader  :point_numbers_rolled
  attr_reader  :table_heat

  from table_state.rb
  delegate :is_hot?, :is_good?, :is_choppy?, :is_cold?,
           :heat_index_in_words,
           :heat_index, to: :table_heat

    @point_numbers_rolled = options[:frequency_counter] || Measure.new('point_numbers_rolled', history_length: history_length)
    point_numbers_rolled.incr
    @table_heat = options[:table_heat] || TableHeat.new(self, history_length)
    =end
class TableHeat

  attr_reader :table_state
  attr_reader :history_length

  POINT_WEIGHT   = 6.0 # making points is heavily weighted
  NUMBERS_WEIGHT = 3.0 # making numbers while trying to make the point
  FRONT_LINE_WINNER_WEIGHT = 1.0 # making 7/11 on come out roll

  COLD_HEAT_RANGE   = (0.0..2.0)
  CHOPPY_HEAT_RANGE = (2.0..4.0)
  GOOD_HEAT_RANGE   = (4.0..5.0)
  HOT_HEAT_RANGE    = (5.0..100.0)

  HOT_NUMBERS_STREAK_INDEX = 5

  def initialize(table_state, history_length)
    @table_state = table_state
    @history_length = history_length
  end

  def heat_index
    points_won, front_line_winners, hot_numbers_average = calc_heat_index

    (points_won          * POINT_WEIGHT) +
    (front_line_winners  * FRONT_LINE_WINNER_WEIGHT) +
    (hot_numbers_average * NUMBERS_WEIGHT)
  end

  def explain
    formatter = "%4.2f * %d"
    points_won, front_line_winners, hot_numbers_average = calc_heat_index
    puts "points_won:          " + formatter % [points_won, POINT_WEIGHT]
    puts "front_line_winners:  " + formatter % [front_line_winners, FRONT_LINE_WINNER_WEIGHT]
    puts "hot_numbers_average: " + formatter % [hot_numbers_average, NUMBERS_WEIGHT]
    puts "yields ==> %4.2f [%s]" % [heat_index, heat_index_in_words]
  end

  def is_hot?
    heat_index_in_words == "HOT"
  end

  def is_good?
    heat_index_in_words == "GOOD"
  end

  def is_choppy?
    heat_index_in_words == "CHOPPY"
  end

  def is_cold?
    heat_index_in_words == "COLD"
  end

  def heat_index_in_words
    case heat_index
      when CHOPPY_HEAT_RANGE
        "CHOPPY"
      when GOOD_HEAT_RANGE
        "GOOD"
      when COLD_HEAT_RANGE
        "COLD"
      when HOT_HEAT_RANGE
        "HOT"
      else
        raise "heat_index #{heat_index} has no matching range"
    end
  end

  private

  def calc_heat_index
    win_loss_record = pass_line_point_bet_stat.last_counts(history_length)
    points_won = win_loss_record[Stat::WON]/(history_length * 1.0)

    win_loss_record = pass_line_bet_stat.last_counts(history_length)
    front_line_winners = win_loss_record[Stat::WON]/(history_length * 1.0)

    hot_numbers_average = table_state.hot_numbers_average/(HOT_NUMBERS_STREAK_INDEX*1.0)

    [points_won, front_line_winners, hot_numbers_average]
  end

  def pass_line_point_bet_stat
    table_state.table.tracking_bet_stats.pass_line_point
  end

  def pass_line_bet_stat
    table_state.table.tracking_bet_stats.pass_line
  end

end
