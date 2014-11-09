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
    pass_line.with_full_odds
    come_out.with_full_odds
    all_the_hardways_for(1)
    across
    field
    ce.for(2)
    ace_deuce.for(1)
    aces.for(1)
    any_craps.for(1)
    any_seven.for(1)
    eleven.for(1)
    twelve.for(1)
  end

end
