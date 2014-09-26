class CoverAllBetsStrategy < BaseStrategy
  #
  # Warning: this is not a viable player strategy. This strategy
  # is only used for the tracking_player making tracking_bets, which
  # keeps stats on all possible outcomes for all playable bets on the table
  #
  def make_bets
    #
    # make pass line bet and pass odds bet
    # make a come bet every time point is on
    # make come odds bet for every come bet established
    # make all proposition bets
    # make c/e bets
    # make all hardways bets and keep them on
    # make all place bets when point is on

    pass_line_bet_with_full_odds
    come_out_bet_with_full_odds
    all_the_hardways
    across
    all_prop_bets
    field
  end

end
