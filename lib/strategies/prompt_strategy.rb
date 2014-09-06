class PromptStrategy < BaseStrategy
  def make_bets
    player.pass_line_bet if table_state.off? unless player.has_bet?(PassLineBet)
    player.pass_odds_bet if table_state.on? &&
                            player.has_bet?(PassLineBet) unless player.has_bet?(PassOddsBet, table_state.point)
    [4,6,8,10].each do |n|
      player.hardways_bet(n, 5) if table_state.point?(n) unless player.has_bet?(HardwaysBet, n)
    end
    [6,8].each do |n|
      player.place_bet(n) unless player.has_bet?(PlaceBet, n) || table_state.point?(n)
    end
  end
end
