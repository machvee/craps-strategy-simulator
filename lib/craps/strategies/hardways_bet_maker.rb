class HardwaysBetMaker < BetMaker
  def initialize(player, number)
    super(player, HardwaysBet.short_name, number)
  end

  def make_or_ensure_bet
    #
    # need to make this bet on_the_point, but then keep it there,
    # and possibly press it, until it loses.
    #
    super
  end

end
