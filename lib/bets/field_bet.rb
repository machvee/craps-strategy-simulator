class FieldBet < CrapsBet
  def name
    "Field Bet"
  end

  def determine_outcome(player_bet)
    outcome = if player_bet.off? 
      Outcome::NONE
    elsif table.fields?
      Outcome::WIN
    end
      Outcome::LOSE
    outcome
  end
end
