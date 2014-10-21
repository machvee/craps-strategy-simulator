class PassOddsBet < CrapsBet

  def name
    "Pass Line Odds Bet #{number}"
  end

  def max_bet
    super * config.max_odds(number)
  end

  def bet_remains_after_win?
    false
  end

  def player_on_status
    OnStatus::FOLLOW
  end

  def makeable?
    table_state.on?
  end

  def validate(player_bet, amount)
    super
    raise "you must have a Pass Line Bet" unless player_bet.player.has_bet?('pass_line_point')
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
    CrapsDice::POINTS.map {|number| PassOddsBet.new(table, number)}
  end
end
