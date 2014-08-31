class FieldBet < CrapsBet
  def name
    "Field Bet"
  end

  def outcome(player_bet)
    result = if player_bet.off? 
      Outcome::NONE
    elsif dice.fields?
      Outcome::WIN
    end
      Outcome::LOSE
    result
  end

  def bet_stats
    [
      OccurrenceState.new('field_win') {dice.fields?},
      *[2,12].map { |v|
        OccurrenceState.new('field_%d_win'%v, Proc.new {dice.fields?}) {dice.rolled?(v)}
      }
    ]
  end
end
