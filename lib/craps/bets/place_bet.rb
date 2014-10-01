class PlaceBet < CrapsBet

  def name
    "Place Bet #{number}"
  end

  def rolls_up
    true
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def outcome
    if rolled_the_number?
      Outcome::WIN
    elsif table_state.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
  end

  def self.gen_number_bets(table)
    CrapsDice::POINTS.map {|number| PlaceBet.new(table, number)}
  end
end
