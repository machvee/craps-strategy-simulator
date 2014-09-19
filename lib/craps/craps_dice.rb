class CrapsDice < Dice
  #
  # regular Dice but with Craps Semantics
  #
  CRAPS   = [2,3,12]
  WINNERS = [7,11]
  HARDS   = [4,6,8,10]
  POINTS  = [4,5,6,8,9,10]
  FIELDS  = [2,3,4,9,10,11,12]

  def seven?
    value == 7
  end

  def eleven?
    value == 11
  end

  def yo?
    eleven?
  end

  def seven_yo?
    winner?
  end

  def winner?
    WINNERS.include?(value)
  end

  def craps?
    CRAPS.include?(value)
  end

  def hard?(value)
    HARDS.include?(value) && same?
  end

  def easy?(value)
    HARDS.include?(value) && !same?
  end

  def points?
    POINTS.include?(value)
  end

  def fields?
    FIELDS.include?(value)
  end

  def rolled?(number)
    number == value
  end
end
