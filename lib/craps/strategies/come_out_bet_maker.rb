class ComeOutBetMaker < OddsBetMaker
  def initialize(player)
    super(player, ComeOutBet.short_name, nil)
  end
end
