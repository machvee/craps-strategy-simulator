class PassLinePointBet < CrapsBet

  def name
    "Pass Line Bet #{number}"
  end

  def rolls_up
    true
  end

  def odds_bet_short_name
    'pass_odds'
  end

  def player_can_set_off?
    false
  end

  def outcome
    if table_state.point_made?
      Outcome::WIN
    elsif table_state.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
  end

  def self.gen_number_bets(table)
    CrapsDice::POINTS.map {|number| PassLinePointBet.new(table, number)}
  end
end
