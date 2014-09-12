class PassLineBet < TableBet

  FRONT_LINE_WINNER_STAT_NAME = 'front_line_winner'
  POINT_MADE_STAT_NAME = 'point_made'

  def initialize(table, number=nil)
    super
    bet_stats.add OccurrenceStat.new(FRONT_LINE_WINNER_STAT_NAME)
    bet_stats.add OccurrenceStat.new(POINT_MADE_STAT_NAME)
  end

  def name
    "Pass Line Bet"
  end

  def player_can_set_off?
    false
  end

  def validate(player_bet, amount)
    super
    raise "point must be off" if table_state.on?
  end

  def outcome
    additional_stats = {}
    result = if table_state.front_line_winner? 
      additional_stats = front_line_winner_stat
      Outcome::WIN
    elsif table_state.crapped_out?
      additional_stats = crapped_out_stat
      Outcome::LOSE
    elsif table_state.point_made?
      additional_stats = point_made_stat
      Outcome::WIN
    elsif table_state.seven_out?
      additional_stats = seven_out_stat
      Outcome::LOSE
    else
      Outcome::NONE
    end
    [result, additional_stats]
  end

  def front_line_winner_stat
    {FRONT_LINE_WINNER_STAT_NAME => OccurrenceStat::WON}
  end

  def crapped_out_stat
    {FRONT_LINE_WINNER_STAT_NAME => OccurrenceStat::LOST}
  end

  def point_made_stat
    {POINT_MADE_STAT_NAME => OccurrenceStat::WON}
  end

  def seven_out_stat
    {POINT_MADE_STAT_NAME => OccurrenceStat::LOST}
  end

end
