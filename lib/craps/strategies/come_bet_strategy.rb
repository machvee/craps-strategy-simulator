class ComeBetStrategy < BaseStrategy

  def name
    "Basic Come Betting"
  end

  def set
    pass_line.with_full_odds
    come_out.at_most(2).with_full_odds
  end

end
