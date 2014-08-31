class CeBet < CrapsBet
  def name
    "C&E Bet"
  end

  def player_can_set_off?
    false
  end

  def outcome(player_bet)
    result = if dice.craps? || dice.eleven?
      Outcome::WIN
    else
      Outcome::LOSE
    end
    result
  end

  def bet_stats
    OccurrenceState.new('ce_bet_win', Proc.new {dice.points? || dice.seven?}) {
      dice.craps? || dice.eleven?
    } 
  end
end
