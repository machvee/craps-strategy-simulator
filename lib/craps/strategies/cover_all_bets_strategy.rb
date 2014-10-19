class CoverAllBetsStrategy < BaseStrategy
  def name
    "tracking bet strategy"
  end

  #
  # Warning: this is not a viable player strategy. This strategy
  # is only used for the tracking_player making tracking_bets, which
  # keeps stats on all possible outcomes for all playable bets on the table
  #
  def set
    #
    # make pass line bet and pass odds bet
    # make a come bet every time point is on
    # make come odds bet for every come bet established
    # make all proposition bets
    # make c/e bets
    # make all hardways bets and keep them on
    # make all place bets when point is on
    pass_line.for(10).with_full_odds
    come_out.for(15).with_full_odds
    all_the_hardways_for(1)
    across_for(10)
    field_bet.for(1)
    ce_bet.for(2)
    ace_deuce_bet.for(1)
    aces_bet.for(1)
    any_craps_bet.for(1)
    any_seven_bet.for(1)
    eleven_bet.for(1)
    twelve_bet.for(1)
  end

end
