class PassLineBetMaker < OddsBetMaker
  def initialize(player)
    super(player, PassLineBet.short_name, nil)
  end
end
