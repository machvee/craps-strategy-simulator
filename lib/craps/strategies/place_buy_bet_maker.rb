class PlaceBuyBetMaker < BetMaker
  #
  # PlaceBuyBetMaker
  # 1. makes direct place bets when bet box is empty
  # 2. makes no place bet made when bet box has a point bet (morphed come/passline bet) unless bets_working
  # 3. makes no place bet when another place/buy bet is present
  #

  def make_or_ensure_bet
    return if bet_not_normally_makeable
    no_place_buy = there_is_no_existing_place_or_buy_bet
    no_pass_come = there_is_no_existing_pass_line_point_or_come_bet
    make_the_bet_if_possible(no_place_buy, no_pass_come) ||
    ensure_bet_to_possibly_bump_bet_amount(!no_place_buy, no_pass_come)
  end

  private

  def make_the_bet_if_possible(no_place_or_buy, no_passline_or_come)
    # make the Place/Buy bet if:
    #   a. no place/buy/pass_line_point/come bet exists in the box
    #   b. no place/buy but there is a come/pass_line and bets_working
    #
    if no_place_or_buy && (no_passline_or_come || bets_working)
      put_down_the_bet
    end
  end

  def ensure_bet_to_possibly_bump_bet_amount(place_or_buy_present, no_passline_or_come)
    #
    # ensure the bet in place if:
    #   a place/buy bet exists AND NO pass_line_point/come bet exists in the box
    #
    if place_or_buy_present && no_passline_or_come
      bet = player.ensure_bet(bet_short_name, bet_presser.next_bet_amount, number)
      bet.maker = self
    end
  end

  def put_down_the_bet
    bet = player.make_bet(bet_short_name, bet_presser.next_bet_amount, number)
    bet.maker = self
  end

  def there_is_no_existing_pass_line_point_or_come_bet
    has_bet = player.has_bet?(PassLinePointBet.short_name, number) ||
              player.has_bet?(ComeBet.short_name, number)
    !has_bet
  end

  def there_is_no_existing_place_or_buy_bet
    has_bet = player.has_bet?(PlaceBet.short_name, number) ||
              player.has_bet?(BuyBet.short_name, number)
    !has_bet
  end
end
