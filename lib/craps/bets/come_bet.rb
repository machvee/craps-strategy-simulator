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

  def outcome
    if rolled_the_number?
      Outcome::WIN
    elsif dice.seven?
      Outcome::LOSE
    else
      Outcome::NONE
    end
  end

  def self.gen_number_bets(table)
    CrapsDice::POINTS.map {|number| ComeBet.new(table, number)}
  end
end
