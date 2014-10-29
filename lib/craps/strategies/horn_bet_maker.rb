class HornBetMaker
  attr_reader   :makers
  attr_reader   :high_number

  def initialize(strategy)
    @makers = {}
    @high_number = nil

    CrapsBet.horn_bets.each_pair do |bet_number, bet_short_name|
      makers[bet_number] = strategy.install_bet(bet_short_name)
    end
  end

  def high(number)
    @high_number = number
    self
  end

  def for(amount)
    CrapsBet.horn_bet_amounts(amount, high_number).each_pair do |bet_number, bet_amount|
      makers[bet_number].for(bet_amount)
    end
    self
  end

  def after_making_point(n)
    horn_bet_makers {|m| m.after_making_point(n)}
    self
  end

  def after_rolls(n)
    horn_bet_makers {|m| m.after_rolls(n)}
    self
  end

  def working
    horn_bet_makers {|m| m.working}
    self
  end

  def on_the_come_out_roll
    horn_bet_makers {|m| m.on_the_come_out_roll}
    self
  end

  def off
    horn_bets_makers {|m| m.off}
    self
  end

  private

  def horn_bet_makers(&block)
    makers.values.each { |m| yield m }
  end

end
