class BasicStrategy < BaseStrategy

  def name
    "Basic"
  end

  def set
    pass_line.
      with_full_odds_on(6, 8).
      with_double_odds_on(5, 9).
      with_single_odds_on(4, 10).
      press_by_additional_bet_unit.after_win(3)
    horn_high_yo.for(5).on_the_come_out_roll.after_making_point(2)
    place_on(6).after_rolls_beyond_first_point(1).press_by_additional_bet_unit.after_win(2).no_press_after_win(10)
    place_on(8).after_rolls_beyond_first_point(1).press_by_additional_bet_unit.after_win(2).no_press_after_win(10)
    place_on(5).after_making_point(1).press_by_additional_bet_unit.after_win(2).no_press_after_win(8)
    place_on(9).after_making_point(2).press_by_additional_bet_unit.after_win(2).no_press_after_win(8)

    buy_the(10).for(25).after_making_point(1).press_by_additional(25).after_win(2).no_press_after_win(6)
    buy_the(4).for(25).after_making_point(3).press_by_additional(25).after_win(2).no_press_after_win(6)

    hard(6).for(2).on_the_point.press_to(10,20,50)
    hard(8).for(2).on_the_point.press_to(10,20,50)
    hard(4).for(2).on_the_point.press_to(10,25,50)
    hard(10).for(2).on_the_point.press_to(10,25,50)
  end

end
