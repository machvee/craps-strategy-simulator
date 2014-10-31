class Run

  DEFAULT_OPTIONS = {
    start_bank:     1000,
    bet_unit:       10,
    strategy:       BasicStrategy,
    exit_criteria:  {shooters: 2}
  }

  attr_reader       :name
  attr_reader       :player
  attr_reader       :table
  attr_accessor     :start_bank
  attr_accessor     :bet_unit
  attr_accessor     :strategy
  attr_accessor     :run_stopper

  delegate :table, to: :player

  def initialize(name, player, options={})
    #
    # options:
    #   start_bank      in dollars
    #   bet_unit        10,15,25, ...
    #   strategy_class  class name
    #   exit_criteria   :down_amount, :up_amount, :down_percent, :up_percent, :points, :shooters
    #                   (whichever comes first if multiple exit strategies)
    #
    opts = DEFAULT_OPTIONS.merge(options)

    @name          = name
    @player        = player

    @start_bank    = opts[:start_bank]
    @bet_unit      = opts[:bet_unit]
    @strategy      = opts[:strategy]]
    @run_stopper   = RunStopper.new(player, opts[:exit_criteria])
  end

  def start
    until run_stopper.stop? do
      table.play
    end
  end

  def save
  end

  def reset
  end

  def self.load(name)
  end

end
