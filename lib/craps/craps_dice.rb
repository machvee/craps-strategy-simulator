class CrapsDice < Dice
  #
  # regular Dice but with Craps Semantics
  #
  CRAPS   = [2,3,12]
  HORN    = [2,3,11,12]
  WINNERS = [7,11]
  HARDS   = [4,6,8,10]
  POINTS  = [4,5,6,8,9,10]
  INSIDE  = [5,6,8,9]
  FIELDS  = [2,3,4,9,10,11,12]
  DICE_FREQUENCY_COUNTS = [0,0,1,2,3,4,5,6,5,4,3,2,1]
  ODDS_OF_ROLLING_A = Hash.new {|h,k| h[k] = ((DICE_FREQUENCY_COUNTS[k]*1.0)/36.0)}

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

  def hard?(hard_value)
    value == hard_value && same?
  end

  def easy?(easy_value)
    value == easy_value && !same?
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

  private

  def additional_watchers
    watcher(:seven)   {|d| d.seven?}
    watcher(:winner)  {|d| d.winner?}
    watcher(:craps)   {|d| d.craps?}
    watcher(:fields)  {|d| d.fields?}
    watcher(:points)  {|d| d.points?}
    HARDS.each do |hv|
      watcher("hard_#{hv}".to_sym)  {|d| d.hard?(hv)} 
      watcher("easy_#{hv}".to_sym)  {|d| d.easy?(hv)} 
    end
  end
end
