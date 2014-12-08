class Callbacks

  attr_reader  :callbacks
  attr_reader  :args
  attr_reader  :labels

  def initialize(labels)
    @callbacks = {}
    @labels = labels
    labels.each {|l| callbacks[l] = []}
  end

  def on(label, &block)
    callbacks[label] << block
  end

  def invoke(label, *args)
    callbacks[label].each {|cb| cb.call(*args)}
  end

  def clear(label)
    callbacks[label].clear
  end

end
