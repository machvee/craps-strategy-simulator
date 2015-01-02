module Watchable
  #
  # Used by an object that changes state.  Each time the state changes the
  # object should call check, which runs through its watchers, and if the watcher condition_proc 
  # is true, it invokes the proc.
  #
  #  e.g.
  #    class Counter
  #       include Watchable
  #       attr_reader :val
  #
  #       def initialize(start=0)
  #         @val = start
  #       end
  #
  #       def inc(incr=1)
  #         @val += incr
  #         check_watchers # call this when state changes
  #       end
  #    end
  #
  #    class Life
  #      attr_reader :current_age
  #      attr_reader :name
  #
  #      def initialize(name)
  #        @name = name
  #        @current_age = Counter.new
  #
  #        current_age.watch("school_age", Proc.new {|age| (5..18).include?(age.val)}) do
  #          puts "Wake up early!! Go catch the bus!"
  #        end
  #
  #        current_age.watch("teenager", Proc.new {|age| (13..19).include?(age.val)}) do
  #          puts "You're a teen.  Be rebellious!"
  #        end
  #
  #        current_age.watch("old", Proc.new {|age| age.val > 64}) do
  #          puts "Dude you're officially old"
  #        end
  #
  #        current_age.watch("centurion", Proc.new {|age| age.val == 100}) do
  #          puts "YOU MADE IT TO 100!!"
  #        end
  #      end
  #
  #      def birthday
  #         current_age.inc
  #         puts "Happy Birthday, #{name}! You're #{current_age.val}"
  #      end
  #    end
  #
  #

  class Watcher
    attr_reader :name
    attr_reader :condition
    attr_reader :callback_proc

    def initialize(name, condition, &block)
      @name = name
      @callback_proc = block;
      @condition = condition
    end
  end

  def watch(name, condition, &block)
    get_watchers[name] = Watcher.new(name, condition, &block)
    return
  end

  def check_watchers
    get_watchers.each_pair { |name, watcher| watcher.callback_proc.call if watcher.condition.call(self) }
    return
  end

  def stop_watching(name)
    get_watchers.delete(name)
    return
  end

  def clear_watchers
    @watchers.clear
  end

  def get_watchers
    @watchers ||= {}
  end

end
