class ComeBetStrategy < BaseStrategy

  def name
    "Basic Come Bet"
  end

  def set
    #
    # TODO: make a certain number of bets (implmement keep(n))
    #       make a certain number of place bets in a certain order when
    #       not covered by the point or a come bet
    #
    pass_line.for(bet_unit).with_full_odds
    place_on(6).for(12).press_to(18,24,30,60,90,120,180)
    place_on(8).for(12).press_to(18,24,30,60,90,120,180)
    come_out.for(bet_unit).at_most(2).with_full_odds
  end

end
