class PlaceBuyBetMaker < BetMaker

  DEFAULT_PLACE_SEQUENCE = [6,8,5,9,4,10]

  attr_reader   :bet_when_number_not_equals_point
  attr_reader   :place_sequence

  def initialize(player, bet_short_name, number=nil)
    super
    @bet_when_number_not_equals_point = false
    @place_sequence = DEFAULT_PLACE_SEQUENCE.reject{|e| e == number}
  end

  def off_the_point
    #
    # useful for place/buy betting to bet only off the point number
    # the bet will be moved/taken down when it exists or would be
    # made on the pass or come point number
    #
    @bet_when_number_not_equals_point = true
    self
  end

  def move_to(*place_bet_box_numbers)
    @place_sequence = place_bet_box_numbers
    self
  end

  def make_or_ensure_bet
    return if bet_not_normally_makeable
    no_place_buy = there_is_no_existing_place_or_buy_bet_on(number)
    no_pass_come = there_is_no_existing_pass_line_point_or_come_bet_on(number)
    make_the_bet_if_possible(no_place_buy, no_pass_come) ||
    move_or_take_down_the_bet_if_necessary(!no_place_buy, !no_pass_come) ||
    ensure_bet_to_possibly_bump_bet_amount(!no_place_buy, no_pass_come)
  end

  private

  def make_the_bet_if_possible(npb, npc)
    # make the Place/Buy bet if:
    #   a. no place/buy/pass_line_point/come bet exists in the box
    #   b. no place/buy but there is a come/pass_line and off_the_point is NOT set
    #
    if npb && (npc || off_the_point_not_set?)
      put_down_the_bet_on(number)
    end
  end

  def move_or_take_down_the_bet_if_necessary(pbe, pce)
    # move or take_down the existing bet if:
    #   a place/buy bet exists AND a pass_line_point/come bet exists and off_the_point IS set
    #
    if pbe && pce && off_the_point_set?
      move_place_buy_bet_or_take_down_if_no_boxes_available
    end
  end

  def ensure_bet_to_possibly_bump_bet_amount(pbe, npc)
    #
    # ensure the bet in place if:
    #   a place/buy bet exists AND NO pass_line_point/come bet exists in the box
    #
    if pbe && npc
      bet = player.ensure_bet(bet_short_name, bet_presser.next_bet_amount, number)
      bet.maker = self
    end
  end

  def move_place_buy_bet_or_take_down_if_no_boxes_available
    #
    # using place_bet_search_order, locate a place bet box with
    # no pass_line_point, come or place/buy bet
    #
    bet_to_move = get_the_current_bet

    player.take_down(bet_to_move)

    place_sequence.each do |place_box_number|
      if box_empty?(place_box_number)
        player.take_down(bet_to_move) 
        put_down_the_bet_on(place_box_number)
        break
      end
    end
  end

  def put_down_the_bet_on(num)
    bet = player.make_bet(bet_short_name, bet_presser.next_bet_amount, num)
    bet.maker = self
  end

  def off_the_point_set?
    bet_when_number_not_equals_point == true
  end

  def off_the_point_not_set?
    !off_the_point_set?
  end

  def there_is_no_existing_pass_line_point_or_come_bet_on(num)
    has_bet = player.has_bet?(PassLinePointBet.short_name, num) ||
              player.has_bet?(ComeBet.short_name, num)
    !has_bet
  end

  def there_is_no_existing_place_or_buy_bet_on(num)
    has_bet = player.has_bet?(PlaceBet.short_name, num) ||
              player.has_bet?(BuyBet.short_name, num)
    !has_bet
  end

  def box_empty?(num)
    there_is_no_existing_place_or_buy_bet_on(num) &&
    there_is_no_existing_pass_line_point_or_come_bet_on(num)
  end

  def get_the_current_bet
    player.find_bet(PlaceBet.short_name, number) ||
    player.find_bet(BuyBet.short_name, number)
  end
end
