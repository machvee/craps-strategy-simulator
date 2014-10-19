class HardwaysBet < CrapsBet

  def name
    "Hardways Bet #{number}"
  end

  def min_bet
    1
  end

  def short_name
    'hard'
  end

  def makeable?
    table_state.on?
  end

  def table_on_status
    OnStatus::FOLLOW # follows the table on/off status
  end

  def outcome
    if dice.seven?
      Outcome::LOSE
    elsif rolled_the_number? 
      if dice.hard?(number)
        Outcome::WIN
      else
        Outcome::LOSE
      end
    else
      Outcome::NONE
    end
  end

  def self.gen_number_bets(table)
    CrapsDice::HARDS.map {|number| HardwaysBet.new(table, number)}
  end
end
