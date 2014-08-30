class HardwaysBet < CrapsBet

  def name
    "Hardways Bet #{number}"
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def determine_outcome(player_bet)
    outcome = if player_bet.off?
      Outcome::NONE
    elsif made_the_number? && table.hard?(number)
      Outcome::WIN
    elsif table.seven? || (made_the_number? && table.easy?(number))
      Outcome::LOSE
    else
      Outcome::NONE
    end
    outcome
  end

  def bet_stats
    OccurrenceStat.new('hard_%d' % number, Proc.new {table.rolled?(number)}) {table.hard?(number)}
  end

  def self.gen_number_bets(table)
    Table::HARDS.map {|number| HardwaysBet.new(table, number)}
  end

end
