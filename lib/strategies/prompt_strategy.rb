class PromptStrategy < BaseStrategy
  def make_bets
    # prompt for bet_name, optional amount (default min_bet) and optional number
    # type a '-' on a line by itself to stop making bets
    player.pass_line_bet if table_state.off? unless player.has_bet?(PassLineBet)
    player.pass_odds_bet if table_state.on? unless player.has_bet?(PassOddsBet, table_state.point)
    [4,6,8,10].each do |n|
      player.hardways_bet(n, 5) if table_state.point == n unless player.has_bet?(HardwaysBet, n)
    end
  end
end
