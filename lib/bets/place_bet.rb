class PlaceBet < CrapsBet

  def name
    "Place Bet #{number}"
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def determine_outcome(player_bet)
    outcome = if player_bet.off?
      Outcome::NONE
    elsif made_the_number?
      Outcome::WIN
    elsif table.seven_out?
      Outcome::LOSE
    else
      Outcome::NONE
    end
    outcome
  end

  def self.gen_number_bets(table)
    Table::POINTS.map {|number| PlaceBet.new(table, number)}
  end
end
