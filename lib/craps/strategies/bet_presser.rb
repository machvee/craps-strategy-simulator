class BetPresser
  #
  # keeps tabs on a bet by name and number, typically place bets and hardways.
  # This is attached to a BetMaker instance.  It keeps track of a bet and the number
  # of consecutive wins.  BetMaker will use the bet_amount method to know how to modify
  # a bet when it is taken down after a win, or while it is active, by returning one
  # of the following:  
  #
  #   1. a new bet amount > 0, possibly higher or lower than previous bet
  #   2. zero, indicating the bet is to be taken down and/or not to be remade
  #
  # the instance stays active on a bet until that bet loses and is taken down, or the instance
  # is destroyed, or a new instance is created matching the bet name and number
  #
  attr_reader   :index
  attr_reader   :press_amounts
  attr_reader   :bet_short_name
  attr_reader   :number

  def initialize(bet_short_name, number)
  end

  def bet_amount
  end
end
