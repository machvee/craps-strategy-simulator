module Watchable
  #
  # when included by a class, the class can set up events with conditional procs, and watchers of 
  # object instances can register named callbacks to be invoked when those events occur
  #
  class Watcher
    attr_reader :condition

    module CallbackType
      ONCE=1    # callback once then remove it
      PERSIST=2 # callback and continue watching
    end

    WatcherCallback = Struct.new(:callback_proc, :callback_type)

    def initialize(condition)
      @condition = condition
      @callback_procs = {}
    end

    def add(name, callback_proc, callback_type=CallbackType::PERSIST)
      raise("callback '#{name}' is already defined for #{name}") if @callback_procs.has_key?(name)
      @callback_procs[name] = WatcherCallback.new(callback_proc, callback_type)
    end

    def remove(name)
      @callback_procs.delete(name)
    end

    def check(obj)
      invoke_callbacks(obj) if fire?(obj)
    end

    def clear
      @callback_procs.clear
    end

    private

    def fire?(obj)
      #
      # should we call any registered callbacks?
      #
      @callback_procs.present? && !!condition.call(obj)
    end

    def invoke_callbacks(obj)
      #
      # iterate through all the registered callbacks and
      # invoke them.  Then, based on the callback type
      # leave them registered or remove them
      #
      @callback_procs.each_pair do |name, callback|

        callback.callback_proc.call(name, obj)

        case callback.callback_type
          when CallbackType::ONCE
            remove(name)
          when CallbackType::PERSIST
            # leave the WatcherCallback in place
        end
      end
    end
  end

  def watcher(name, &block)
    #
    # used by the Watchable to set up named events.  Consumers of the Watchable object
    # can watch_for these events and have their callbacks invoked when the events are
    # true
    #
    raise "watcher '#{name}' already defined" if watchers.has_key?(name)
    watchers[name] = Watcher.new(block)
    return
  end

  def watch_for(name, cb_name, &block)
    watcher_valid?(name)
    watchers[name].add(cb_name, block)
    return
  end

  def watch_for_once(name, cb_name, &block)
    watcher_valid?(name)
    watchers[name].add(cb_name, block, Watcher::CallbackType::ONCE)
    return
  end

  def watch_always(cb_name, &block)
    watchers[:always].add(cb_name, block)
  end

  def watch_it(name, conditional_proc=Proc.new {true}, &block)
    #
    # Consumer of watchable can create their own event with this and
    # watch for it
    #
    watcher(name, &conditional_proc)
    watch_for(name, name, &block)
  end

  def watch_it_once(name, conditional_proc=Proc.new {true}, &block)
    #
    # Consumer of watchable can create their own event with this and
    # watch for it
    #
    watcher(name, &conditional_proc)
    watch_for_once(name, name, &block)
  end

  def check_watchers
    #
    # Watchable object must invoke this each time watchable state changes
    #
    watchers.each_pair { |name, watcher| watcher.check(self) }
    return
  end

  def stop_watching(name, cb_name)
    watchers[name].remove(cb_name)
    return
  end

  def clear_watchers
    watchers.each_pair {|name, watcher| watcher.clear}
  end

  def watchers
    #
    # the :always watcher callbacks will be invoked each time check_watchers is 
    # invoked by the Watchable
    #
    @all_watchers ||= {always: Watcher.new(Proc.new {true})}
  end

  def watcher_valid?(name)
    raise "invalid watcher #{name}" unless watchers.has_key?(name)
  end

end
