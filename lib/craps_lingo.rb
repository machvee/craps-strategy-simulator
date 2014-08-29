module CrapsLingo
  #
  # Table dependencies
  # depends on last_roll (dice.value)
  # depends on on? and off? prior to updating the table state with the current dice.value
  # depends on point
  #

  CRAPS   = [2,3,12]
  WINNERS = [7,11]
  HARDS   = [4,6,8,10]
  POINTS  = [4,5,6,8,9,10]
  FIELDS  = [2,3,4,9,10,11,12]

  def seven?
    last_roll== 7
  end

  def eleven?
    last_roll == 11
  end

  def yo?
    eleven?
  end

  def seven_yo?
    winner?
  end

  def winner?
    WINNERS.include?(last_roll)
  end

  def craps?
    CRAPS.include?(last_roll)
  end

  def hard?(value)
    HARDS.include?(last_roll) && dice.same?
  end

  def easy?(value)
    HARDS.include?(last_roll) && !dice.same?
  end

  def point_established?(value=nil)
    #
    # only true when transitioning in to a new point
    # but the table has not yet been marked ON
    #
    off? && points? && match_roll?(value)
  end

  def points?
    POINTS.include?(last_roll)
  end

  def fields?
    FIELDS.include?(last_roll)
  end

  def point_made?(value=nil)
    on? && (last_roll == point) && match_roll?(value)
  end

  def seven_out?
    on? && seven?
  end

  def front_line_winner?(value=nil)
    off? && winner? && match_roll?(value)
  end

  def crapped_out?(value=nil)
    off? && craps? && match_roll?(value)
  end

  def yo_eleven?
    front_line_winner?(11)
  end

  def winner_seven?
    front_line_winner?(7)
  end

  def stickman_says
    if point_made?
      "winner #{last_roll}. pay the line" 
    elsif seven_out?
      "7 out"
    elsif front_line_winner?
      "7 front line winner!"
    elsif yo_eleven?
      "yo 11!" 
    elsif crapped_out?
      "crap!" 
    elsif point_established?
      "the point is #{last_roll}"
    else
      ""
    end
  end

  private

  def match_roll?(value)
    value.nil? || (value == last_roll)
  end

end
