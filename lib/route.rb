class Route
  def do_any(&block)
    @block = block
  end

  def call
    @block.call
  end
end
