class PassLineBet < CrapsBet

  def initialize(table, number=nil)
    super
    morphs_to('pass_line_point')
  end

  def name
    "Pass Line Bet"
  end

  def player_can_set_off?
    false
  end

  def validate(player_bet, amount)
    super
    raise "point must be off" if table_state.on?
  end

  def outcome
    if table_state.front_line_winner? 
      Outcome::WIN
    elsif table_state.crapped_out?
      Outcome::LOSE
    elsif dice.points?
      Outcome::MORPH
    end
  end
end
