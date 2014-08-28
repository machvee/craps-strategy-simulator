class ComeBet < CrapsBet
  def name
    "Come Bet on #{number}"
  end

  def player_can_set_off?
    false
  end

  def bet_remains_after_win?
    false
  end

  def determine_outcome(player_bet)
    outcome = if made_the_number?
      Outcome::WIN
    elsif table.seven?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    outcome
  end

  def self.gen_number_bets(table)
    Table::POINTS.map {|number| ComeBet.new(table, number)}
  end
end
