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
    result = if table_state.front_line_winner? 
      # update_front_line_winner_stats(player_bet)
      Outcome::WIN
    elsif table_state.crapped_out?
      # update_crapped_out_stats(player_bet)
      Outcome::LOSE
    elsif table_state.point_made?
      # update_point_made_stats(player_bet)
      Outcome::WIN
    elsif table_state.seven_out?
      # update_seven_out_stats(player_bet)
      Outcome::LOSE
    else
      Outcome::NONE
    end
    result
  end

  def update_front_line_winner_stats(player_bet)
    bet_stats.occurred(FRONT_LINE_WINNER_STAT_NAME)
    player_bet.stat_occurred(FRONT_LINE_WINNER_STAT_NAME)
  end

  def update_crapped_out_stats(player_bet)
    bet_stats.did_not_occur(FRONT_LINE_WINNER_STAT_NAME)
    player_bet.stat_did_not_occur(FRONT_LINE_WINNER_STAT_NAME)
  end

  def update_point_made_stats(player_bet)
    bet_stats.occurred(POINT_MADE_STAT_NAME)
    player_bet.stat_occurred(POINT_MADE_STAT_NAME)
  end

  def update_seven_out_stats(player_bet)
    bet_stats.did_not_occur(POINT_MADE_STAT_NAME)
    player_bet.stat_did_not_occur(POINT_MADE_STAT_NAME)
  end

end
