class ComeBetStrategy < BaseStrategy

  def name
    "Basic Come Betting with Place 6 or 8"
  end

  def set
    #
    # TODO: make a certain number of bets (implmement keep(n))
    #       make a certain number of place bets in a certain order when
    #       not covered by the point or a come bet
    #
    pass_line.with_full_odds
    place_on(6).press_by_additional_bet_unit.no_press_after_win(5)
    place_on(8).press_by_additional_bet_unit.no_press_after_win(5)
    come_out.at_most(2).with_full_odds
  end

end
