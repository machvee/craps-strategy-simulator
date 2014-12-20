class HardwaysBetMaker < BetMaker
  def initialize(player, number)
    super(player, HardwaysBet.short_name, number)
  end

  def make_or_ensure_bet
    #
    # need to make this bet on_the_point, but once made, keep it there until the bet loses
    # possibly pressing it as it may win again along the way
    #
    if already_made_the_required_number_of_bets
      return if bets_off
      player.ensure_bet(bet_short_name, bet_presser.next_bet_amount, number)
    else
      return if bet_when_number_equals_point && number_is_not_point? 
      make_the_bet
    end
  end

end
